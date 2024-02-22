#!/usr/bin/env groovy
@Library("product-pipelines-shared-library") _

// Automated release, promotion and dependencies
properties([
  // Include the automated release parameters for the build
  release.addParams(),
  // Dependencies of the project that should trigger builds
  dependencies([])
])

pipeline {
  agent { label 'conjur-enterprise-common-agent' }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    timeout(time: 1, unit: 'HOURS')
  }

  triggers {
    cron(getDailyCronString())
  }

  environment {
    // Sets the MODE to the specified or autocalculated value as appropriate
    MODE = release.canonicalizeMode()
  }

  parameters {
    booleanParam(name: 'TEST_OCP_NEXT', defaultValue: false, description: 'Run Conjur Enterprise tests against our running "next version" of Openshift')
    booleanParam(name: 'TEST_OCP_OLDEST', defaultValue: false, description: 'Run Conjur Enterprise tests against our running "oldest version" of Openshift')
  }

  stages {

    stage('Get InfraPool ExecutorV2 Agent') {
      steps {
        dir("deploy/kubernetes-conjur-deploy") {
          checkout([
          $class: 'GitSCM',
          branches: [[name: '*/master']],
          doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
          extensions: [[$class: 'CloneOption', noTags: false, shallow: false, depth: 0, reference: '']],
          userRemoteConfigs: [[url: 'https://github.cyberng.com/Conjur-Enterprise/kubernetes-conjur-deploy', credentialsId: 'jenkins_ci_token' ]] ,
          ])
        }
        script {
          INFRAPOOL_EXECUTORV2_AGENT_0 = getInfraPoolAgent.connected(type: "ExecutorV2", quantity: 1, duration: 2)[0]
        }
      }
    }

    // Aborts any builds triggered by another project that wouldn't include any changes
    stage("Skip build if triggering job didn't create a release") {
      when {
        expression {
          MODE == "SKIP"
        }
      }
      steps {
        script {
          currentBuild.result = 'ABORTED'
          error("Aborting build because this build was triggered from upstream, but no release was built")
        }
      }
    }

    stage("Run E2E test flow") {
      steps {
        script {
          def tasks = [:]
          tasks["Kubernetes GKE"] = {
            INFRAPOOL_EXECUTORV2_AGENT_0.agentSh "./bin/start --docker --gke"
          }
          tasks["OpenShift (Current)"] = {
            INFRAPOOL_EXECUTORV2_AGENT_0.agentSh "./bin/start --docker --current"
          }
          if ( params.TEST_OCP_OLDEST ) {
            tasks["OpenShift (Oldest)"] = {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh "./bin/start --docker --oldest"
            }
          }
          if ( params.TEST_OCP_NEXT ) {
            tasks["OpenShift (Next)"] = {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh "./bin/start --docker --next"
            }
          }
          parallel tasks
        }
      }
    }

  }
}
