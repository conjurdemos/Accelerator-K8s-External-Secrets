#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: conjur-jwt
  namespace: ${APP_NAMESPACE_NAME}
spec:
  provider:
    conjur:
      url: https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local
      caProvider:
        type: "Secret"
        name: "conjur-details"
        namespace: "${APP_NAMESPACE_NAME}"
        key: "certificate"
      auth:
        jwt:
          account: ${CONJUR_ACCOUNT}
          serviceID: ${AUTHENTICATOR_ID}
          serviceAccountRef:
            name: ${APP_SERVICE_ACCOUNT_NAME}
            audiences:
              - https://conjur-follower.$CONJUR_NAMESPACE_NAME.svc.cluster.local
EOL
