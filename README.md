# 🛠️ WebApp Monitoring System

This repository provides a complete solution to deploy and monitor a secure, cloud-native Java web application using infrastructure as code on AWS and GCP.

---

## 📁 Project Structure

| Folder         | Description                                                                 |
|----------------|-----------------------------------------------------------------------------|
| [`tf-aws-infra`](./tf-aws-infra) | Terraform configurations for provisioning AWS infrastructure (VPC, EC2, RDS, S3, IAM, CloudWatch, ALB, Route53, etc.) |
| [`webapp`](./webapp)             | Spring Boot microservice for file management and health monitoring, integrated with AWS S3 and MySQL on RDS |

---

## 🚀 Overview

This system combines:

- 📦 **Infrastructure-as-Code** using Terraform and Packer
- 🔐 **Security Best Practices** with IAM, KMS, SSL/ACM, and private subnets
- 📈 **Full-stack Observability** using AWS CloudWatch Agent and GCP Ops Agent
- ⚙️ **Auto Scaling & Load Balancing** for high availability
- ☁️ **Multi-cloud readiness** with deployment and monitoring across **AWS** and **GCP**

---

## 🧰 Technologies Used

- **Backend**: Java 21, Spring Boot 3, Hibernate, JPA, MySQL
- **DevOps**: Terraform, Packer, GitHub Actions
- **Cloud Providers**:
  - AWS: EC2, S3, RDS, IAM, CloudWatch, ACM, ALB, Route 53
  - GCP: Ops Agent for metrics collection
- **Security**: KMS, Secrets Manager, IAM roles
- **Testing**: JUnit, Mockito
- **Build Tool**: Apache Maven

---

## 📄 Usage

See each submodule's README for details:

- [📦 Terraform AWS Infra Setup →](./tf-aws-infra/README.md)
- [🌐 Cloud Application Microservice →](./webapp/README.md)

---

## 👨‍💻 Maintainer

**Srivarini Mandali**  
🔗 [GitHub](https://github.com/srivarinimandali)
