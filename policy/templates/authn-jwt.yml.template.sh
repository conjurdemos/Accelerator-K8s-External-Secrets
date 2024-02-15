#!/usr/bin/env bash

set -euo pipefail
cat << EOL
---
- !policy
  id: conjur/authn-jwt/${AUTHENTICATOR_ID}
  owner: !group cluster_admin
  annotations:
    description: Configuration for AuthnJWT service
  body:
    - !webservice

    # - !variable jwks-uri
    - !variable public-keys
    - !variable issuer
    - !variable token-app-property
    - !variable identity-path
    - !variable audience

    # Group of applications that can authenticate using this JWT Authenticator
    - !layer users
  
    - !permit
      role: !layer users
      privilege: [ read, authenticate ]
      resource: !webservice

    - !webservice status
   
    # Group of users who can check the status of the JWT Authenticator
    - !group operators
   
    - !permit
      role: !group operators
      privilege: [ read ]
      resource: !webservice status
EOL
