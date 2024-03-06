#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $APP_SERVICE_ACCOUNT_NAME
  namespace: $APP_NAMESPACE_NAME
EOL
