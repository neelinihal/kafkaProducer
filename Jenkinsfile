pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  tools {
    jdk 'JDK17'       // Name must match your Global Tool Configuration
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
    GCP_CREDS    = 'gcp-sa-json'   // Jenkins credential ID
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
          sh 'mvn -version'
          sh 'mvn clean package -Dmaven.test.failure.ignore=false'
        }
      }
    }

    stage('Docker build') {
      steps {
        dir(MODULE_DIR) {
          sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
        }
      }
    }

    stage('Docker login & push') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh 'docker logout || true'
          sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
        }

        sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"

        // Update Kubernetes manifest with the new image tag
        sh "sed -i 's|image: neelinihal/producer:.*|image: neelinihal/producer:${IMAGE_TAG}|g' deployment.yaml"
      }
    }

    stage('Authenticate GCP') {
      steps {
        withCredentials([file(credentialsId: "${GCP_CREDS}", variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh "gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS"
          sh "gcloud config set project ${PROJECT_ID}"
          sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${PROJECT_ID}"
        }
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh "kubectl apply -f deployment.yaml --namespace=${KUBE_NS} --validate=false"
        // sh "kubectl rollout restart deployment/${DEPLOY_NAME} -n ${KUBE_NS}"
        // sh "kubectl rollout status deployment/${DEPLOY_NAME} -n ${KUBE_NS}"
      }
    }
  }
}
