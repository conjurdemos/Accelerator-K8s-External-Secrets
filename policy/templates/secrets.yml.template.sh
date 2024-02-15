#!/usr/bin/env bash

set -euo pipefail
cat << EOL
# Should be loaded into root
- !policy
  id: secrets
  body:
    - &variables
      - !variable test_secret

    - !layer users

    - !permit
      resources: *variables
      role: !layer users
      privileges: [ read, execute ]

- !grant
  role: !layer secrets/users
  members:
    - !host conjur/authn-jwt/${AUTHENTICATOR_ID}/apps/system:serviceaccount:${APP_NAMESPACE_NAME}:test-app-sa
EOL
