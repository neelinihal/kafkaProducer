pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    REPO_URL     = 'https://github.com/neelinihal/kafkaProducer.git'
    GIT_BRANCH   = 'producer'
    MODULE_DIR   = '.'
    IMAGE_NAME   = 'neelinihal/producer'
    IMAGE_TAG    = "build-${env.BUILD_NUMBER}"
    DOCKER_CREDS = 'dockerhub-creds'
    KUBE_NS      = 'default'
    DEPLOY_NAME  = 'producer'
    CONTAINER    = 'producer'
    GCP_CREDS    = 'gcp-sa-json'
    CLUSTER_NAME = 'my-cluster'
    CLUSTER_ZONE = 'us-central1'
    PROJECT_ID   = 'steel-earth-478506-t2'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([$class: 'GitSCM',
          branches: [[name: "*/${GIT_BRANCH}"]],
          userRemoteConfigs: [[url: REPO_URL]]
        ])
      }
    }

    stage('Build (Maven)') {
      steps {
        dir(MODULE_DIR) {
          bat 'mvn -version'
          bat 'mvn clean package -Dmaven.test.failure.ignore=false'
        }
      }
    }

    stage('Docker build') {
      steps {
        dir(MODULE_DIR) {
          bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
        }
      }
    }

    stage('Docker login & push') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          bat 'docker logout || ver > nul'
          bat 'docker login -u %DOCKER_USER% -p %DOCKER_PASS%'
        }

        bat "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
        bat "docker push ${IMAGE_NAME}:${IMAGE_TAG}"

        bat "powershell -Command \"(Get-Content deployment.yaml) -replace 'image: neelinihal/producer:.*', 'image: neelinihal/producer:${IMAGE_TAG}' | Set-Content deployment.yaml\""
      }
    }

    stage('Authenticate GCP') {
      steps {
        withCredentials([file(credentialsId: "${GCP_CREDS}", variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          bat "\"C:/Users/neeli/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud\" auth activate-service-account --key-file=%GOOGLE_APPLICATION_CREDENTIALS%"
          bat "\"C:/Users/neeli/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud\" config set project ${PROJECT_ID}"
          bat "\"C:/Users/neeli/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud\" container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${PROJECT_ID}"
        }
      }
    }

    stage('Deploy to GKE') {
      steps {
        bat "kubectl apply -f deployment.yaml --namespace=${KUBE_NS} --validate=false"
        // bat "kubectl rollout restart deployment/${DEPLOY_NAME} -n ${KUBE_NS}"
        // bat "kubectl rollout status deployment/${DEPLOY_NAME} -n ${KUBE_NS}"
      }
    }
  }
}
