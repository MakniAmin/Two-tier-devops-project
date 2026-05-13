pipeline {
    agent any

    // ── Global variables ──────────────────────────────
    environment {
        IMAGE_NAME      = "two-tier-flask-app"
        DOCKERHUB_USER  = "your-dockerhub-username"    // change this
        GITHUB_REPO     = "https://github.com/your-username/two-tier-flask-app.git" // change this

        // These reference credentials stored in Jenkins
        // Add them in: Jenkins → Manage Jenkins → Credentials
        DOCKERHUB_CREDS = credentials('dockerhub-credentials')
    }

    options {
        timeout(time: 15, unit: 'MINUTES')   // kill build if it hangs
        disableConcurrentBuilds()             // don't run 2 builds at once
        buildDiscarder(logRotator(numToKeepStr: '5')) // keep only last 5 builds
    }

    stages {

        // ── Stage 1: Get the code ──────────────────────
        stage('Clone Repository') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        // ── Stage 2: Run tests ─────────────────────────
        stage('Test') {
            steps {
                echo "🧪 Running tests..."
                sh '''
                    pip install -r requirements.txt --quiet
                    # Run pytest if tests/ folder exists
                    if [ -d "tests" ]; then
                        pytest tests/ -v
                    else
                        echo "No tests folder found, skipping..."
                    fi
                '''
            }
        }

        // ── Stage 3: Build Docker image ────────────────
        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest
                """
            }
        }

        // ── Stage 4: Push to DockerHub ─────────────────
        stage('Push to DockerHub') {
            steps {
                echo "📤 Pushing image to DockerHub..."
                sh """
                    docker login -u ${DOCKERHUB_CREDS_USR} -p ${DOCKERHUB_CREDS_PSW}
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:latest ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
                    docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        // ── Stage 5: Deploy ────────────────────────────
        stage('Deploy with Docker Compose') {
            steps {
                echo "🚀 Deploying application..."
                sh '''
                    # Stop existing containers gracefully
                    docker compose down || true

                    # Pull latest images and start fresh
                    docker compose up -d --build

                    # Wait and verify containers are healthy
                    sleep 15
                    docker compose ps
                '''
            }
        }
    }

    // ── Post actions (always run after stages) ─────────
    post {
        success {
            echo "✅ Pipeline succeeded! App is live at http://<EC2-IP>:5000"
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
        always {
            echo "🧹 Cleaning up unused Docker images..."
            sh 'docker image prune -f'
        }
    }
}