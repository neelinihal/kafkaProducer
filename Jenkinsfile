pipeline {
  agent any

  tools {  // ADD THIS BLOCK
    jdk 'jdk-17'
    maven 'Maven 3.9.11'  // Or your Maven version name
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    skipDefaultCheckout()
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
          sh 'java -version'   // Verify Java 17 from tools block
          sh 'mvn -version'    // Verify Maven + Java 17
          sh 'mvn clean package -Dmaven.test.failure.ignore=false'
        }
      }
    }

    // ... rest of your stages unchanged
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
        sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
        sh "sed -i 's|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g' deployment.yaml"
      }
    }

    stage('Authenticate GCP') {
      steps {
        withCredentials([file(credentialsId: "${GCP_CREDS}", variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh "gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS"
          sh "gcloud config set project ${PROJECT_ID}"
          sh "gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${CLUSTER_ZONE} --project ${PROJECT_ID}"
        }
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh "kubectl apply -f deployment.yaml --namespace=${KUBE_NS} --validate=false"
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completed successfully. Image ${IMAGE_NAME}:${IMAGE_TAG} deployed to ${CLUSTER_NAME} in namespace ${KUBE_NS}."
    }
    failure {
      echo "❌ Pipeline failed. Please check logs for details."
    }
    always {
      cleanWs()
    }
  }
}
