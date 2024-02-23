#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: $APP_SERVICE_ACCOUNT_NAME-secret
  namespace: $APP_NAMESPACE_NAME
  annotations:
    kubernetes.io/service-account.name: "$APP_SERVICE_ACCOUNT_NAME"
EOL
