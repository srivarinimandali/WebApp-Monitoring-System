# 🌐 Cloud Application: A File Management & Health Check Microservice

Cloud Application is a robust, RESTful microservice designed to monitor application health and manage file storage using AWS S3. It features comprehensive error handling, logging, and infrastructure automation to ensure scalability, security, and reliability.

## 🚀 Key Features

- **Health Check API**
  Monitors database connectivity and application health, ensuring system reliability.
- **File Management API**
  Supports uploading, retrieving metadata, and deleting files stored in AWS S3, providing seamless file management capabilities.
- **Infrastructure Automation**
  Utilizes Terraform to automate the deployment of EC2, RDS, and S3, ensuring a scalable and secure infrastructure.
- **Security-First Design**

  - **Private S3 Bucket**: Encrypted storage with lifecycle policies for cost optimization.
  - **Private RDS**: MySQL database deployed in a private subnet, inaccessible from the public internet.
  - **IAM Role-Based Access**: Secure access to S3 from EC2 without hardcoded credentials.

## 🛠️ Technology Stack

<p align="center">
  <img src="https://img.shields.io/badge/Java-21-%23ED8B00?style=for-the-badge&logo=java&logoColor=white">
  <img src="https://img.shields.io/badge/Spring_Boot-3.1.5-%236DB33F?style=for-the-badge&logo=springboot&logoColor=white">
  <img src="https://img.shields.io/badge/MySQL-8.0-%234479A1?style=for-the-badge&logo=mysql&logoColor=white">
  <img src="https://img.shields.io/badge/Hibernate-6.2-%2359666C?style=for-the-badge&logo=hibernate&logoColor=white">
  <img src="https://img.shields.io/badge/JPA-3.1-%23007396?style=for-the-badge&logo=java&logoColor=white">
  <img src="https://img.shields.io/badge/AWS_S3-%23FF9900?style=for-the-badge&logo=amazons3&logoColor=white">
  <img src="https://img.shields.io/badge/AWS_RDS-%23232F3E?style=for-the-badge&logo=amazonrds&logoColor=white">
  <img src="https://img.shields.io/badge/AWS_EC2-%23FF9900?style=for-the-badge&logo=amazonec2&logoColor=white">
  <img src="https://img.shields.io/badge/Terraform-1.5-%23843CE0?style=for-the-badge&logo=terraform&logoColor=white">
  <img src="https://img.shields.io/badge/HikariCP-5.0-%23009688?style=for-the-badge&logo=java&logoColor=white">
  <img src="https://img.shields.io/badge/Apache_Maven-3.9.5-%23C71A36?style=for-the-badge&logo=apachemaven&logoColor=white">
  <img src="https://img.shields.io/badge/Logback-1.4.7-%23000000?style=for-the-badge&logo=logback&logoColor=white">
  <img src="https://img.shields.io/badge/JUnit-5.9-%2325A162?style=for-the-badge&logo=junit5&logoColor=white">
  <img src="https://img.shields.io/badge/Mockito-5.4-%23E91E63?style=for-the-badge&logo=mockito&logoColor=white">
</p>

## ⚙️ Prerequisites

Before setting up the application, ensure the following are installed and configured:

1. **Java Development Kit (JDK) 21**
2. **Apache Maven** for dependency management and project building.
3. **MySQL Database** with the necessary access privileges.

## 📌 API Overview

- **Health Check API**: Monitors application and database health, returning `200 OK` if healthy or `503 Service Unavailable` if there are connectivity issues.
- **Upload File API**: Uploads files to AWS S3 using `multipart/form-data`.
- **Get File Metadata API**: Retrieves metadata for a specific file stored in S3.
- **Delete File API**: Deletes a file from AWS S3 based on its unique identifier.

## 🚀 Deployment Instructions

### 🖥️ Local Deployment

1. **Clone the Repository:**

   ```bash
   git clone <repository-url>
   cd cloud-application
   ```
2. **Build the Project:**

   ```bash
   mvn clean install
   ```
3. **Run the Application:**

   ```bash
   java -jar target/cloud-0.0.1-SNAPSHOT.jar
   ```

### ☁️ Deploy to AWS EC2

1. Ensure Terraform infrastructure is deployed.
2. Copy JAR file to EC2:
   ```bash
   scp -i <your-key.pem> target/cloud-0.0.1-SNAPSHOT.jar ubuntu@<EC2-PUBLIC-IP>:/opt/app/
   ```
3. Restart the service:
   ```bash
   sudo systemctl restart webapp.service
   ```

## 🛠️ Potential Issues & Troubleshooting

### ⚠️ **AWS S3 Issues**

- **File Upload Failures**: Ensure the IAM role attached to the EC2 instance has sufficient permissions (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`).
- **Bucket Access Denied**: Verify the S3 bucket policy allows access from the EC2 instance's IAM role.
- **Lifecycle Policy Misconfiguration**: Ensure lifecycle policies are correctly configured to avoid unexpected file transitions or deletions.

### ⚠️ **AWS RDS Issues**

- **Connection Timeouts**: Verify the RDS instance is running and accessible from the EC2 instance in the private subnet.
- **IAM Authentication Failures**: Ensure the IAM role for the EC2 instance has the `rds-db:connect` permission.
- **Database Credentials Mismatch**: Double-check the `DB_URL`, `DB_USERNAME`, and `DB_PASSWORD` environment variables.

### ⚠️ **General Issues**

- **Port Conflicts**: If port `8080` is in use, modify `server.port` in `application.properties`.
- **Terraform Deployment Failures**: Ensure Terraform is configured with the correct AWS credentials and region.

## 📛 Logging & Monitoring

The application logs every request, response, and error using **SLF4J** and **Logback** for comprehensive monitoring.

- **INFO** → Successful health checks and API calls.
- **WARN** → Invalid requests and potential issues.
- **ERROR** → Database issues and unexpected failures.

## 👨‍💻 Developer

📌 **Srivarini Mandali**
🔗 **[GitHub](https://github.com/srivarini-mandali)**




