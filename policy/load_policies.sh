#!/bin/sh
set -xeuo pipefail

readonly POLICY_DIR="/policy"

# NOTE: generated files are prefixed with the test app namespace to allow for parallel CI
set -- "$POLICY_DIR/users.yml" \
  "$POLICY_DIR/generated/$APP_NAMESPACE_NAME.hosts.yml" \
  "$POLICY_DIR/generated/$APP_NAMESPACE_NAME.authn-jwt.yml" \
  "$POLICY_DIR/generated/$APP_NAMESPACE_NAME.authn-jwt-apps.yml" \
  "$POLICY_DIR/generated/$APP_NAMESPACE_NAME.secrets.yml" \

for policy_file in "$@"; do
  echo "Loading policy $policy_file..."
  conjur policy load -b root -f "$policy_file"
done

# Configure AuthnJWT
conjur variable set -i "conjur/authn-jwt/$AUTHENTICATOR_ID/token-app-property" -v "sub"
conjur variable set -i "conjur/authn-jwt/$AUTHENTICATOR_ID/issuer" -v "$ISSUER"
conjur variable set -i "conjur/authn-jwt/$AUTHENTICATOR_ID/public-keys" -v "{\"type\":\"jwks\", \"value\":$(cat /policy/jwks.json)}"
conjur variable set -i "conjur/authn-jwt/$AUTHENTICATOR_ID/identity-path" -v "conjur/authn-jwt/$AUTHENTICATOR_ID/apps"
conjur variable set -i "conjur/authn-jwt/$AUTHENTICATOR_ID/audience" -v "https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local"
