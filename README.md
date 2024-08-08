# Accelerator: Conjur and External Secrets Operator

This accelerator simulates a real-world end-to-end workflow where
[External Secrets Operator](https://external-secrets.io/latest/) is used to
deliver secrets stored in Conjur Enterprise to an application running in
Kubernetes. It can be used as a starting point for integrating Conjur with
External Secrets Operator.

## Certification Level

![Certified](https://img.shields.io/badge/Certification%20Level-Certified-28A745?link=https://github.com/cyberark/community/blob/master/Conjur/conventions/certification-levels.md)

This repo is a **Certified** level project. It's been reviewed by CyberArk to verify that it will securely
work with CyberArk Conjur Enterprise as documented. In addition, CyberArk offers Enterprise-level support for these features. For
more detailed  information on our certification levels, see [our community guidelines](https://github.com/cyberark/community/blob/master/Conjur/conventions/certification-levels.md#community).

## Prerequisites

| Dependency                | Minimum Version |
|---------------------------|-----------------|
| Kubernetes                | 1.19.0          |
| External Secrets Operator | 0.9.0           |
| Conjur Enterprise         | 12.5            |

ESO is also compatible with [Conjur OSS](https://github.com/cyberark/conjur) and [Conjur Cloud](https://www.cyberark.com/products/multi-cloud-secrets/).

## Part I: Setup

Update `demo-vars.sh` with the appropriate values. Notable settings include:

| Environment Variable     | Description |
|--------------------------|-------------|
| `CONJUR_APPLIANCE_IMAGE` | Image used to deploy a Conjur Appliance leader and follower to Kubernetes. |
| `DEV` | Keep the environment running until it's stopped. Set to `true` for an interactive environment. |
| `LOCAL` | Run the demo workflow against a local K8s cluster. |
| `RUN_IN_DOCKER` | Run the demo workflow from a Docker container with `kubectl`, `oc`, and other required tools installed. |
| `PLATFORM` | Set to either `kubernetes` or `openshift`. |

Update `secrets.yml` with the appropriate values:

| Desired Outcome | Required Environment Variables |
|-----------------|--------------------------------|
| Install demo to GKE cluster | <ul><li>`GCLOUD_CLUSTER_NAME`<li>`GCLOUD_ZONE`<li>`GCLOUD_PROJECT_NAME`<li>`GCLOUD_SERVICE_KEY`</ul> |
| Install demo to Openshift cluster | <ul><li>`OPENSHIFT_VERSION`<li>`OPENSHIFT_URL`<li>`OPENSHIFT_USERNAME`<li>`OPENSHIFT_PASSWORD`<li>`OSHIFT_CLUSTER_ADMIN_USERNAME`<li>`OSHIFT_CONJUR_ADMIN_USERNAME`</ul> |

## Part II: Start

Begin the demo workflow by running:

```sh
./bin/start
```

The script performs the following:
1. Deploys a Conjur Enterprise leader and follower
   1. Creates a batch of secrets representing a connection to an external database
   2. Creates and configures a JWT Authenticator instance
2. Deploys External Secrets Operator
3. Deploys a PostgreSQL database
4. Creates the following K8s resources:
   - ServiceAccount and associated Secret
   - Secret containing a Conjur host ID, API key, and SSL certificate
   - [SecretStore](https://external-secrets.io/latest/api/secretstore/)
     that is
     [configured for API key authentication](https://external-secrets.io/latest/provider/conjur/#external-secret-store-definition-with-apikey-authentication)
   - [ExternalSecret](https://external-secrets.io/latest/api/externalsecret/)
     mapping
     [Conjur secrets to a K8s Secret](https://external-secrets.io/latest/provider/conjur/#create-external-secret-definition)
5. Deploys a Pet Store demo application that connects to the PostgreSQL database
   using the secrets delivered from Conjur by External Secrets Operator

Once the demo application is deployed, use the Pet Store as described
[here](https://github.com/conjurdemos/pet-store-demo/blob/main/README.md).

## Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get
started and descriptions of our development workflows, please see our [contributing
guide][contrib].
[contrib]: CONTRIBUTING.md

## License

Copyright (c) 2024 CyberArk Software Ltd. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

For the full license text see [`LICENSE`](LICENSE).
