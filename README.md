
### ***CI/CD Pipeline using Jenkins, Terraform, Ansible and Docker to Deploy Flask Application on AWS***
---
*ABOUT THIS PROJECT*:

This project demonstrates how to build and deploy a web application automatically using CI/CD. The project uses a host EC2 machine to run Jenkins, Terraform, Ansible, and Docker, and then automatically creates another EC2 instance where the Flask application will be deployed inside a Docker container. The entire process happens with one click or by pushing code to GitHub.

The main goal of this project is to understand how automation happens in real world DevOps workflows, and how different DevOps tools connect with each other.

---

## **ARCHITECTURE / WORKING FLOW** 

Developer pushes code to GitHub →

Jenkins pipeline starts automatically →

1. Jenkins builds Docker image of the Flask app.
2. Jenkins pushes the image to Docker Hub.
3. Jenkins uses Terraform to create a new EC2 instance.
4. Jenkins retrieves the EC2 instance public IP from Terraform output.
5. Jenkins generates Ansible inventory using that IP.
6. Jenkins runs Ansible playbook:

   * Installs Docker in the new EC2 instance.
   * Pulls image from Docker Hub.
   * Runs the container.
7. User opens the public IP in browser and sees the Flask UI.

---

## **TOOLS USED**

AWS EC2       - To host servers.

Jenkins       - To automate the pipeline.

Docker        - To containerize and run the application.

Terraform     - To create AWS resources automatically.

Ansible       - To configure the EC2 instance and deploy the container.

GitHub        - To store project source code.

Python Flask  - Simple web UI application.

---

## **SET UP PROCESS STEP BY STEP** 

*LAUNCH JENKINS HOST SERVER*

Instance Type : t2.medium

AMI           : Amazon Linux 2


## **CONFIGURATION OF IAM ROLE**

Terraform needs permission to create EC2, Security Groups, etc.
Instead of using **AWS Access Keys** (NOT recommended), we will attach an **IAM Role** to the EC2 instance running Jenkins.

This IAM Role grants permissions to Terraform automatically.


## **STEP 1: Create IAM Role**

1. Go to AWS Console → **IAM**
2. Left Menu → **Roles**
3. Click **Create Role**
4. **Select Trusted Entity**:
   Choose: **AWS Service**
5. Under "Use Case", choose: **EC2**
6. Click **Next**

---

## **STEP 2: Attach Permissions to the Role**

Search and add these policies:

| Policy Name             | Purpose                                   |
| ----------------------- | ----------------------------------------- |
| **AmazonEC2FullAccess** | Allows Terraform to create EC2 instances  |
| **AmazonVPCFullAccess** | Allows creating security groups, networks |

**If you want LIMITED access later, we can create a custom policy. For now full access is fine for learning.**

Click **Next**

---

## **STEP 3: Name the Role**

Give the role a clear name:

```
jenkins-terraform-role
```

Click **Create Role**.

---

## **STEP 4: Attach the Role to Jenkins EC2 Instance**

1. Go to AWS Console → **EC2**
2. Select your **Jenkins Host Instance (t2.medium)**
3. Click **Actions** (top right)
4. Select → **Security**
5. Click → **Modify IAM Role**
6. From dropdown → Select **jenkins-terraform-role**
7. Click **Apply**

✅ Now Terraform running inside Jenkins host instance will automatically have AWS permissions.

---

## **INSTALL DEPENDENCIES (GIT, DOCKER, TERRAFORM, ANSIBLE, JENKINS)**

**Update system**

```
sudo yum update -y
```

**Install Git**

```
sudo yum install git -y

git -v     # To Verify git installation
```

**Install Docker**

```
sudo yum install docker -y
# Install Docker Engine on the system

docker -v
# Verify docker installation

sudo systemctl start docker  
# Start the Docker service so it begins running now

sudo systemctl enable docker 
# Enable Docker service to start automatically on system boo 

sudo usermod -aG docker ec2-user
# Add the 'ec2-user' to the 'docker' group so this user can run Docker commands WITHOUT needing sudo every time 

```

(Logout and login again to apply permissions)

**Install Jenkins**

```
sudo yum install java-17-amazon-corretto -y         
#To install Jenkins we need to install java 17 before because it is a java based application.

java -version 
# Verify Java installation

sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat stable/jenkins.repo  
# Download and save the official Jenkins repository configuration so yum can fetch Jenkins packages


sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
# Import Jenkins GPG key to verify package authenticity and security

sudo yum install fontconfig java-17-amazon-corretto -y
# Ensure fontconfig and Java runtime are installed (required for Jenkins to run properly)  

sudo yum install jenkins -y 
# Install Jenkins package from the Jenkins yum repository 

sudo usermod -aG docker Jenkins
# Add the Jenkins user to the 'docker' group so Jenkins can run Docker commands without permission errors

sudo systemctl restart docker
# Restart Docker service to update group permissions changes

sudo systemctl start Jenkins    
# Start Jenkins service 

sudo systemctl enable Jenkins     
# Enable Jenkins to start automatically on server boot
```

**INSTALL TERRAFORM**

```
sudo yum install -y yum-utils shadow-utils     # Dependencies

sudo yum-config-manager --add-repo [https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo](https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo)   # Terraform repo

sudo yum install terraform -y     # Install Terraform
```

---

**INSTALL ANSIBLE**

```
sudo amazon-linux-extras install epel -y     # Enable extra repo

sudo yum install ansible -y     # Install Ansible
```

## Access Jenkins from your browser:

```
http://<your-ec2-public-ip>:8080
```

Find admin password: Run this command in instance terminal to get the password for Jenkins login

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Follow setup steps and install suggested plugins.

---

## CONFIGURE CREDENTIALS IN JENKINS

Open Jenkins → Manage Jenkins → Credentials → Add Credentials

Add:

1. DockerHub username + password  
   *Enter dockerhub username and password or Token(Recommanded)
   *(ID: aws-ssh-key)

2. SSH Private Key 
   *Enter instance username(ec2-user) and direct paste the .pem file contents
   *(ID: aws-ssh-key)

---

## **CLONE GITHUB REPOSITORY IN JENKINS**

1. Create a New Item → Choose "Pipeline".
2. Name: Flask-UI
3. Under Triggers section :
   * Enable GitHub hook trigger for GITScm polling option
4. Under Pipeline Definition:

   * Choose "Pipeline script from SCM"
   * SCM: Git
   * Repository URL:

```
https://github.com/mohanreddybodha/CI-CD-project-using-jenkins-terraform-ansible-docker.git
```

* Script Path:

```
jenkinsfile
```

4. Save and run the job.

---

## CONFIGURE WEBHOOK FOR AUTOMATION

1. Go to GitHub → Repository Settings → Webhooks → Add Webhook
2. Payload URL:

```
http://<your-ec2-public-ip>:8080/github-webhook/
```

3. Content type:

```
application/json
```

4. Select: Just the push event

5. Save

Now every time you push code to GitHub, Jenkins will automatically trigger the pipeline.

---


## **TERRAFORM FILE** (main.tf inside terraform folder)

```

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow inbound traffic for web UI"

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0a34b530c620f51a2" # Amazon Linux 2 for ap-south-1
  instance_type          = "t2.micro"
  key_name               = "mohan1"  #  Replace with your actual key pair name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = { 
    Name = "flask-ui-docker"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Key points:

* Uses Amazon Linux 2 AMI
* Uses security groups allowing port 22 and 80
* Uses your key-pair name

---

## **ANSIBLE PLAYBOOK** (deploy.yml inside ansible folder)

```

- name: Deploy Flask UI via Docker
  hosts: web
  become: yes
  vars:
    image_name: "mohanreddybodha/flask-ui:latest"
    container_name: "flask-ui"
    host_port: 80
    container_port: 5000

  tasks:
    - name: Install docker
      yum:
        name: docker
        state: present

    - name: Start & enable docker
      service:
        name: docker
        state: started
        enabled: yes

    - name: Add ec2-user to docker group (no sudo for docker)
      user:
        name: ec2-user
        groups: docker
        append: yes

    - name: Pull image
      command: docker pull {{ image_name }}

    - name: Stop old container if exists
      shell: |
        if [ "$(docker ps -q -f name={{ container_name }})" ]; then
          docker stop {{ container_name }} && docker rm {{ container_name }}
        fi
      ignore_errors: yes

    - name: Run container
      command: >
        docker run -d --restart always
        -p {{ host_port }}:{{ container_port }}
        --name {{ container_name }}
        {{ image_name }}
```

This playbook:

* Installs Docker in the target EC2 instance
* Pulls Docker image from DockerHub
* Runs the container

---

## **JENKINS PIPELINE FILE** (jenkinsfile)

```
pipeline {
  agent any

  environment {
    DOCKERHUB_USER = "mohanreddybodha"
    IMAGE_NAME     = "flask-ui"
    IMAGE_TAG      = "latest"
    APP_DIR        = "app"
    TF_DIR         = "terraform"
    ANS_DIR        = "ansible"
    SSH_USER       = "ec2-user"
    SSH_CRED       = "aws-ssh-key"    // Jenkins Credentials ID (SSH private key)
    DOCKER_CRED    = "dockerhub-creds"// Jenkins Credentials ID (username+password)
  }

  options { timestamps(); timeout(time: 30, unit: 'MINUTES') }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push Docker Image') {
      steps {
        dir(APP_DIR) {
          script {
            docker.withRegistry('https://registry.hub.docker.com', DOCKER_CRED) {
              def img = docker.build("${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}")
              img.push()
            }
          }
        }
      }
    }

    stage('Terraform Apply') {
      when { changeset "**/terraform/**" }
      steps {
        dir(TF_DIR) {
          sh """
            terraform init -input=false
            terraform apply -auto-approve -input=false
          """
        }
      }
    }

    stage('Generate Ansible Inventory') {
      steps {
        script {
          def ip = sh(script: "cd ${TF_DIR} && terraform output -raw public_ip", returnStdout: true).trim()
          writeFile file: "${ANS_DIR}/inventory.ini",
                   text: "[web]\n${ip} ansible_user=${SSH_USER}\n"
          echo "Target EC2 IP => ${ip}"
        }
      }
    }

    stage('Deploy with Ansible') {
      steps {
        sshagent(credentials: [SSH_CRED]) {
          dir(ANS_DIR) {
            sh "ansible --version"
            sh "ansible-playbook -i inventory.ini deploy.yml --ssh-extra-args='-o StrictHostKeyChecking=no'"
          }
        }
      }
    }
  }

  post {
    success {
      echo " Deployment complete. Open: http://<EC2_PUBLIC_IP>"
    }
    failure {
      echo " Failed. Check the console logs."
    }
  }
}
```
The pipeline:

1. Checks out code
2. Builds and pushes Docker image
3. Applies Terraform only if Terraform files changed
4. Retrieves EC2 instance IP
5. Runs Ansible deployment

---

## **DOCKERFILE** (dockerfile inside app folder)


```
# Use official Python 3.9 slim image as base (lightweight + stable)
FROM python:3.9-slim

# Set working directory inside the container
WORKDIR /app

# Copy dependencies list into container
COPY requirements.txt .

# Install required Python packages without storing cache (reduces image size)
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code into container
COPY . .

# Expose port 5000 to allow external access to the app
EXPOSE 5000

# Command to run the application when container starts
CMD ["python", "app.py"]
```


## **COMMON ERRORS AND FIXES**

ERROR : Permission denied (publickey)

Cause : Wrong username.

Fix   : For Amazon Linux use `ec2-user`, not `ubuntu`.



ERROR : ssh-agent could not find credentials

Cause : Incorrect credential ID.

Fix   : Ensure Jenkins credential ID matches ID in Jenkinsfile.



ERROR : Docker permission denied

Cause : Jenkins user not in docker group.

Fix   :

      sudo usermod -aG docker jenkins 
  
      sudo systemctl restart jenkins




ERROR : Terraform AMI error

Cause : Region mismatch.

Fix   : Always select correct AMI for region.


## WHAT I UNDERSTOOD FROM THIS PROJECT

I learned:

* How CI/CD automation works in real production style.
* How Terraform creates cloud infrastructure automatically.
* How Ansible configures servers and deploys containers.
* How Jenkins acts as the automation controller.
* How Docker enables consistent application packaging.

This project improved my understanding of DevOps workflow connectivity.



## 👨‍💻 About Me

**Name:** Mohan Reddy Bodha

**GitHub:** [github.com/mohanreddybodha](https://github.com/mohanreddybodha)

**DockerHub:** [hub.docker.com/u/mohanreddybodha](https://hub.docker.com/u/mohanreddybodha)

**Email:** [mohanreddybodha05@gmail.com](mailto:mohanreddybodha05@gmail.com)

**LinkedIn:** [https://www.linkedin.com/in/mohan-reddy-boda-0560722b7/](https://www.linkedin.com/in/mohan-reddy-boda-0560722b7/)



## END OF GUIDE

This document provides step-by-step instructions for anyone — even beginners with zero prior DevOps experience — to deploy and automate a Flask-UI web application using Jenkins CI/CD on AWS EC2.

> “Even the simplest project done perfectly speaks louder than a complex one left incomplete.”

⭐ If you liked this project, give it a **star** on GitHub!
