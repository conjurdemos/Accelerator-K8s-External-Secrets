#!/usr/bin/env bash

#######
# Default Conjur configuration
#######
export CONJUR_MINOR_VERSION=5.0
export CONJUR_APPLIANCE_IMAGE=registry.tld/conjur-appliance:$CONJUR_MINOR_VERSION-stable
export CONJUR_ACCOUNT=conjur
export CONJUR_ADMIN_PASSWORD=ADmin123!!!!
export CONJUR_LOG_LEVEL=debug
export DEPLOY_MASTER_CLUSTER=true
export CONJUR_FOLLOWER_COUNT=1
export AUTHENTICATOR_ID=eso-env
export CONJUR_AUTHENTICATORS="authn,authn-jwt/$AUTHENTICATOR_ID"
export CONJUR_HOST_ID=demo-app
export CONJUR_HOST_API_KEY=to-be-updated-once-host-created
export CONJUR_CERTIFICATE=to-be-updated-once-conjur-deployed

#######
# Default test env
#######
export DEV=false
export LOCAL=false
export RUN_IN_DOCKER=true
export STOP_RUNNING_ENV=true
export TEST_RUNNER_IMAGE=accelerator-test-runner
export UNIQUE_TEST_ID="${UNIQUE_TEST_ID:-$(uuidgen | tr "[:upper:]" "[:lower:]" | head -c 10)}"

export PLATFORM=kubernetes
export SUMMON_ENV=gke
export TEST_PLATFORM=gke

#######
# Default K8s configuration
#######
export CONJUR_NAMESPACE_NAME=accelerator-conjur-$UNIQUE_TEST_ID
export APP_NAMESPACE_NAME=accelerator-apps-$UNIQUE_TEST_ID
export ESO_NAMESPACE_NAME=accelerator-external-secrets
export APP_SERVICE_ACCOUNT_NAME=test-app-sa

#######
# Default demo app database configuration
#######
export DB_PASSWORD="P0stgre5P@ss%"
export DB_PLATFORM=postgres
export DB_TABLE=demo-app
export DB_USERNAME=db-user

#######
# Local dev env (uncomment all lines if using this configuration)
# Uses current kubectl context. Be sure to target your local cluster.
#######
# export DEV=true
# export LOCAL=true
# export RUN_IN_DOCKER=false
#
# export SUMMON_ENV=common
#
# export CONJUR_NAMESPACE_NAME=accelerator-conjur
# export APP_NAMESPACE_NAME=accelerator-apps
# export ESO_NAMESPACE_NAME=external-secrets

#######
# Remote dev env using GKE (uncomment all lines if using this configuration)
#######
# export DEV=true
# export LOCAL=false
# export RUN_IN_DOCKER=true
#
# export CONJUR_NAMESPACE_NAME=accelerator-conjur
# export APP_NAMESPACE_NAME=accelerator-apps
# export ESO_NAMESPACE_NAME=external-secrets

#######
# Remote dev env using OpenShift (uncomment all lines if using this configuration)
#######
# export DEV=true
# export LOCAL=false
# export RUN_IN_DOCKER=true
#
# export PLATFORM=openshift
# export SUMMON_ENV=current
# export TEST_PLATFORM=openshift
#
# export CONJUR_NAMESPACE_NAME=accelerator-conjur
# export APP_NAMESPACE_NAME=accelerator-apps
# export ESO_NAMESPACE_NAME=external-secrets

