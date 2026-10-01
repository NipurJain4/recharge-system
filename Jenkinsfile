// Jenkins pipeline for recharge-system (lives in the app repo).
//
// Flow (GitOps):
//   1. Build the image with KANIKO (no Docker daemon needed).
//   2. Push to ECR — auth via the NODE role (SCP-excluded, auto-refreshing).
//   3. Update the image tag in the GitOps repo and commit.
//      Flux + Flagger then deploy + run the canary.
//
// Required Jenkins credential:
//   - 'github-token' : GitHub PAT (repo scope) to push the tag commit.

pipeline {
  agent {
    kubernetes {
      yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.23.2-debug
      command: ["/busybox/cat"]
      tty: true
    - name: tools
      image: alpine/git:latest
      command: ["cat"]
      tty: true
'''
    }
  }

  environment {
    AWS_REGION  = 'ap-south-1'
    ACCOUNT_ID  = '821410798987'
    ECR_REPO    = 'podinfo'
    REGISTRY    = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    IMAGE_TAG   = "recharge-b${env.BUILD_NUMBER}"
    GITOPS_REPO = 'github.com/NipurJain4/eks-canary-gitops.git'
    MANIFEST    = 'apps/recharge-system/deployment.yaml'
  }

  stages {
    stage('Build & push image (Kaniko)') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --context `pwd` \
              --dockerfile Dockerfile \
              --destination ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG} \
              --verbosity info
          '''
        }
      }
    }

    stage('Bump image tag in GitOps repo') {
      steps {
        container('tools') {
          withCredentials([string(credentialsId: 'github-token', variable: 'GH_TOKEN')]) {
            sh '''
              rm -rf gitops && git clone https://$GH_TOKEN@$GITOPS_REPO gitops
              cd gitops
              sed -i "s#${ECR_REPO}:recharge-[a-zA-Z0-9._-]*#${ECR_REPO}:${IMAGE_TAG}#" ${MANIFEST}
              git config user.email "jenkins@ci"
              git config user.name "jenkins-ci"
              git commit -am "ci: recharge-system image -> ${IMAGE_TAG} (build ${BUILD_NUMBER})"
              git push origin main
            '''
          }
        }
      }
    }
  }

  post {
    success {
      echo "Pushed ${REGISTRY}/${ECR_REPO}:${IMAGE_TAG} and committed to GitOps. Flux + Flagger will run the canary."
    }
  }
}
