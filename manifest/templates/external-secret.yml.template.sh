#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: external-secret
  namespace: ${APP_NAMESPACE_NAME}
spec:
  refreshInterval: 10s
  secretStoreRef:
    name: conjur-api-key
    kind: SecretStore
  target:
    name: target-secret
    creationPolicy: Owner
  data:
  - secretKey: secret-key
    remoteRef:
      key: secrets/test_secret
EOL
