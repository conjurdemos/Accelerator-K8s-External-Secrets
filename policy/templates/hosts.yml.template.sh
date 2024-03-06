#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
- !host
  id: ${CONJUR_HOST_ID}
  annotations:
    description: Host used to test Conjur-ESO integration with API key auth
EOL
