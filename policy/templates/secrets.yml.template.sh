#!/usr/bin/env bash

set -euo pipefail
cat << EOL
# Should be loaded into root
- !policy
  id: secrets
  body:
    - &variables
      - !variable test_secret
      - !variable db/url
      - !variable db/username
      - !variable db/password
      - !variable db/platform

    - !layer users

    - !permit
      resources: *variables
      role: !layer users
      privileges: [ read, execute ]

- !grant
  role: !layer secrets/users
  members:
    - !host conjur/authn-jwt/${AUTHENTICATOR_ID}/apps/system:serviceaccount:${APP_NAMESPACE_NAME}:${APP_SERVICE_ACCOUNT_NAME}

- !grant
  role: !layer secrets/users
  members:
    - !host ${CONJUR_HOST_ID}
EOL
