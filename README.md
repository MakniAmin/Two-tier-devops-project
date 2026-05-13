# Two-Tier Flask Application with CI/CD Pipeline

A production-ready two-tier web application built with Flask and MySQL,
fully containerized with Docker and deployed automatically via a Jenkins CI/CD pipeline on AWS EC2.

---

## 🏗️ Architecture

```
Developer
    │
    │  git push
    ▼
GitHub Repository
    │
    │  webhook trigger
    ▼
Jenkins (AWS EC2 :8080)
    │
    ├── Stage 1: Clone code
    ├── Stage 2: Run tests
    ├── Stage 3: Build Docker image
    ├── Stage 4: Push to DockerHub
    └── Stage 5: Deploy with Docker Compose
                      │
                      ▼
            ┌─────────────────────┐
            │   two-tier network  │
            │                     │
            │  Flask App :5000    │
            │       │             │
            │       │ SQL queries │
            │       ▼             │
            │  MySQL DB  :3306    │
            │  (mysql-data vol.)  │
            └─────────────────────┘
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Flask | Python web framework |
| MySQL | Relational database |
| Docker | Containerization |
| Docker Compose | Multi-container orchestration |
| Jenkins | CI/CD automation |
| AWS EC2 | Cloud server |
| GitHub | Source control + webhook trigger |

---

## 📁 Project Structure

```
two-tier-flask-app/
├── app.py                  # Flask application
├── requirements.txt        # Python dependencies
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Container orchestration
├── Jenkinsfile             # CI/CD pipeline definition
├── .env.example            # Environment variable template
├── .gitignore              # Files excluded from git
└── README.md               # This file
```

---

## 🚀 Run Locally

### Prerequisites
- Docker and Docker Compose installed
- Git installed

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/your-username/two-tier-flask-app.git
cd two-tier-flask-app

# 2. Set up environment variables
cp .env.example .env
# Edit .env and fill in your values
nano .env

# 3. Build and start containers
docker compose up -d --build

# 4. Verify containers are running
docker compose ps

# 5. Open the app
# http://localhost:5000
```

### Useful Commands

```bash
# View logs
docker compose logs -f

# Stop the app
docker compose down

# Stop and delete all data (careful!)
docker compose down -v

# Get shell inside Flask container
docker compose exec flask bash

# Get shell inside MySQL container
docker compose exec mysql bash
```

---

## ⚙️ Jenkins CI/CD Setup

### 1. Install Jenkins on EC2

```bash
# Install Java
sudo apt update
sudo apt install -y openjdk-17-jdk

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update && sudo apt install -y jenkins

# Allow Jenkins to run Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### 2. Add DockerHub Credentials in Jenkins
```
Jenkins → Manage Jenkins → Credentials → Add Credentials
Kind: Username with password
ID: dockerhub-credentials
Username: your-dockerhub-username
Password: your-dockerhub-password
```

### 3. Create Pipeline Job
```
New Item → Pipeline
Pipeline → Definition: Pipeline script from SCM
SCM: Git
Repository URL: https://github.com/your-username/two-tier-flask-app.git
Script Path: Jenkinsfile
```

### 4. Add GitHub Webhook
```
GitHub repo → Settings → Webhooks → Add webhook
Payload URL: http://<EC2-IP>:8080/github-webhook/
Content type: application/json
Trigger: Just the push event
```

---

## 🔒 Security Notes

- All secrets are stored in `.env` (not committed to Git)
- `.env.example` shows required variables with placeholder values
- Docker container runs as non-root user
- MySQL is not exposed publicly in production (remove port mapping)

---

## 📊 EC2 Security Group Rules

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | Your IP | SSH access |
| 8080 | TCP | Your IP | Jenkins UI |
| 5000 | TCP | 0.0.0.0/0 | Flask app (public) |
| 3306 | TCP | Private only | MySQL (internal) |