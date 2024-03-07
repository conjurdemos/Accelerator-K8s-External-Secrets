#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
source ./bin/utils

conjur_dir="$(repo_root)/deploy/kubernetes-conjur-deploy"
policy_dir="$(repo_root)/policy"
manifest_dir="$(repo_root)/manifest"
db_config_dir="$(repo_root)/deploy/db"

function cleanup {
  pushd "$(repo_root)"
    ./bin/stop
  popd
}
trap cleanup ERR
if [[ "$DEV" != "true" ]]; then
  trap cleanup ERR EXIT
fi

pushd "$conjur_dir"
  announce "Deploying Conjur Enterprise"

  # In kubernetes-conjur-deploy, the DEV envvar indicates that the user wants
  # Conjur deployed to a local Docker Desktop K8s cluster.
  old_dev=$DEV
  # In this project, we want DEV to indicate that the user wants a live,
  # interactive env using their choice of K8s flavor, and LOCAL to indicate the
  # user wants Conjur deployed to Docker Desktop.
  export DEV=$LOCAL

  ./start
  export DEV=$old_dev

  # Now that Conjur Enterprise is deployed, store the SSL cert in an envvar
  export CONJUR_CERTIFICATE="$(conjur_ssl_cert)"
popd

pushd "$policy_dir"
  announce "Generating Conjur policy"

  mkdir -p ./generated
  ./templates/authn-jwt.yml.template.sh      > ./generated/$APP_NAMESPACE_NAME.authn-jwt.yml
  ./templates/authn-jwt-apps.yml.template.sh > ./generated/$APP_NAMESPACE_NAME.authn-jwt-apps.yml
  ./templates/hosts.yml.template.sh          > ./generated/$APP_NAMESPACE_NAME.hosts.yml
  ./templates/secrets.yml.template.sh        > ./generated/$APP_NAMESPACE_NAME.secrets.yml

  announce "Loading Conjur policy and configuring AuthnJWT"

  ISSUER="$($cli get --raw /.well-known/openid-configuration | jq -r '.issuer')"
  JWKS_URI="$($cli get --raw /.well-known/openid-configuration | jq -r '.jwks_uri')"
  $cli get --raw "$JWKS_URI" > jwks.json

  cli_pod="$(pod_name "$CONJUR_NAMESPACE_NAME" 'app=conjur-cli')"
  $cli exec "$cli_pod" -- rm -rf /policy
  $cli cp "$policy_dir" "$cli_pod:/policy"

  configure_conjur_cli
  $cli exec "$cli_pod" -- sh -c "
    APP_NAMESPACE_NAME=${APP_NAMESPACE_NAME} \
    AUTHENTICATOR_ID=${AUTHENTICATOR_ID} \
    CONJUR_NAMESPACE_NAME=${CONJUR_NAMESPACE_NAME} \
    DB_PASSWORD=${DB_PASSWORD} \
    DB_PLATFORM=${DB_PLATFORM} \
    DB_URL="postgresql://db.${APP_NAMESPACE_NAME}.svc.cluster.local:5432/${DB_TABLE}" \
    DB_USERNAME=${DB_USERNAME} \
    ISSUER=${ISSUER} \
    /policy/load_policies.sh
  "

  # Now that test Conjur resources have been created, store the API key for
  # host $CONJUR_HOST_ID in an envvar
  export CONJUR_HOST_API_KEY="$(rotate_host_api_key "$CONJUR_HOST_ID")"
popd

announce "Installing External Secrets Operator"

helm repo add external-secrets https://charts.external-secrets.io
helm repo update

if [[ "$PLATFORM" == "openshift" ]]; then
  $cli adm policy add-scc-to-user \
    anyuid \
    "system:serviceaccount:$ESO_NAMESPACE_NAME:external-secrets"
fi

# ESO Helm chart can only be installed once per K8s cluster, which caused
# failures when pipelines are built simultaneously. Given this, we need to
# install the ESO Helm chart to a single namespace, and reach a consensus before
# uninstalling it.
if helm list -n "$ESO_NAMESPACE_NAME" | grep -q eso; then
  echo "ESO Helm chart already installed - skipping"
else
  helm install eso external-secrets/external-secrets \
    -n "$ESO_NAMESPACE_NAME" \
    --create-namespace \
    --wait \
    --timeout "5m" \
    --values "./deploy/eso/values.${PLATFORM}.yml"
fi

# The mechanism to determine consensus are unique labels on the ESO namespace,
# formatted 'conjur.org/$UNIQUE_TEST_ID'. Each pipeline will add its own unique
# label set to 'PENDING', and set it to 'DONE' once it consents to uninstalling.
if [[ "$DEV" == "false" ]]; then
  $cli label namespace "$ESO_NAMESPACE_NAME" "conjur.org/$UNIQUE_TEST_ID=PENDING"
fi

pushd "$manifest_dir"
  announce "Generate manifests for test configuration"

  mkdir -p ./generated
  ./templates/conjur-connection-secret.yml.template.sh > ./generated/$APP_NAMESPACE_NAME.conjur-connection-secret.yml
  ./templates/service-account.yml.template.sh          > ./generated/$APP_NAMESPACE_NAME.service-account.yml
  ./templates/service-account-secret.yml.template.sh   > ./generated/$APP_NAMESPACE_NAME.service-account-secret.yml
  ./templates/api-key-provider.yml.template.sh         > ./generated/$APP_NAMESPACE_NAME.api-key-provider.yml
  ./templates/jwt-provider.yml.template.sh             > ./generated/$APP_NAMESPACE_NAME.jwt-provider.yml
  ./templates/external-secret.yml.template.sh          > ./generated/$APP_NAMESPACE_NAME.external-secret.yml
  ./templates/demo-app.yml.template.sh                 > ./generated/$APP_NAMESPACE_NAME.demo-app.yml

  announce "Configuring application namespace"

  $cli create namespace "$APP_NAMESPACE_NAME"
  $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.service-account.yml
  $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.conjur-connection-secret.yml
  $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.service-account-secret.yml
popd

pushd "$db_config_dir"
  announce "Deploying demo app backend"

  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  helm install postgresql bitnami/postgresql -n "$APP_NAMESPACE_NAME" \
    --wait \
    --timeout "5m" \
    --set "auth.username=$DB_USERNAME" \
    --set "auth.password=$DB_PASSWORD" \
    --set "auth.database=$DB_TABLE" \
    --values "./values.${PLATFORM}.yml"
popd

if [[ "$DEV" != "true" ]]; then
  go test -v ./e2e
else
  announce "Setting up demo environment"

  pushd "$manifest_dir"
    $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.api-key-provider.yml
    $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.external-secret.yml
    $cli apply -n "$APP_NAMESPACE_NAME" -f ./generated/$APP_NAMESPACE_NAME.demo-app.yml
    $cli apply -n "$APP_NAMESPACE_NAME" -f ./curl.yml
  popd

  $cli exec curl -n "$APP_NAMESPACE_NAME" -- curl \
    -X POST \
    -H 'Content-Type: application/json' \
    --data '{"name":"Accelerator Alice"}' \
    "http://demo-app.$APP_NAMESPACE_NAME.svc.cluster.local:8080/pet"
fi
