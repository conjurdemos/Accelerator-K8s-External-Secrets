#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
- !policy
  id: conjur/authn-jwt/${AUTHENTICATOR_ID}/apps
  annotations:
    description: Identities permitted to authenticate with the AuthnJWT service
  body:
    - !layer

    - &hosts
      - !host
        id: system:serviceaccount:${APP_NAMESPACE_NAME}:${APP_SERVICE_ACCOUNT_NAME}
        annotations:
          authn-jwt/${AUTHENTICATOR_ID}/sub: system:serviceaccount:${APP_NAMESPACE_NAME}:${APP_SERVICE_ACCOUNT_NAME}

      # This host will not have permissions on Conjur secrets to test this use-case
      - !host
        id: ${APP_NAMESPACE_NAME}/service_account/${APP_NAMESPACE_NAME}:${APP_SERVICE_ACCOUNT_NAME}

    - !grant
        role: !layer
        members: *hosts

- !grant
    role: !layer conjur/authn-jwt/${AUTHENTICATOR_ID}/users
    member: !layer conjur/authn-jwt/${AUTHENTICATOR_ID}/apps
EOL
