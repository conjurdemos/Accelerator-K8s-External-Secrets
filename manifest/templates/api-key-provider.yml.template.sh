#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: conjur-api-key
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
        apikey:
          account: ${CONJUR_ACCOUNT}
          userRef:
            name: conjur-details
            key: hostID
          apiKeyRef:
            name: conjur-details
            key: apiKey
EOL
