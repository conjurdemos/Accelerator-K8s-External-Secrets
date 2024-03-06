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
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: url
    remoteRef:
      key: secrets/db/url
  - secretKey: username
    remoteRef:
      key: secrets/db/username
  - secretKey: password
    remoteRef:
      key: secrets/db/password
  - secretKey: platform
    remoteRef:
      key: secrets/db/platform
EOL
