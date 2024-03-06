#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
apiVersion: v1
kind: Secret
metadata:
  name: conjur-details
  namespace: ${APP_NAMESPACE_NAME}
stringData:
  hostID: host/${CONJUR_HOST_ID}
  apiKey: ${CONJUR_HOST_API_KEY}
  certificate: |
$(echo "${CONJUR_CERTIFICATE}" | while read line; do printf "%4s%s\n" "" "$line"; done)
EOL
