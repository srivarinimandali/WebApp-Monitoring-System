# Terraform AWS Infrastructure Setup

This repository contains Terraform configurations to provision and manage AWS cloud infrastructure for a web application.

---

## 📌 Prerequisites

Before running Terraform, ensure the following dependencies are installed and configured:

1. Terraform : Install Terraform from [here](https://www.terraform.io/downloads.html).
2. AWS CLI   : Install AWS CLI from [here](https://aws.amazon.com/cli/).
3. AWS IAM   : Ensure the IAM user or role used for Terraform has sufficient permissions to create and manage AWS resources.
4. **Set up AWS credentials** using the AWS CLI:

   ```bash
   aws configure


   ```

## 🚀 Infrastructure Components

![VPC](https://img.shields.io/badge/VPC-Public%20%26%20Private%20Subnets-%23007EC6?style=for-the-badge)
![EC2](https://img.shields.io/badge/EC2-IAM%20Role%20%7C%20KMS%20Encryption%20%7C%20Secure%20Access-%23FF9900?style=for-the-badge&logo=amazonec2&logoColor=white)
![RDS](https://img.shields.io/badge/RDS-MySQL%20%7C%20KMS%20Encrypted%20%7C%20Private-%234479A1?style=for-the-badge&logo=mysql&logoColor=white)
![S3](https://img.shields.io/badge/S3-KMS%20Encrypted%20%7C%20Versioning%20%7C%20Lifecycle-%23FF4F00?style=for-the-badge&logo=amazons3&logoColor=white)
![Security Groups](https://img.shields.io/badge/Security%20Groups-App%2C%20LB%2C%20RDS%20Access%20Control-%233C3C3C?style=for-the-badge)
![IAM](https://img.shields.io/badge/IAM-Roles%20%7C%20Policies%20%7C%20CloudWatchAgent-%23232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![KMS](https://img.shields.io/badge/KMS-EC2%2C%20RDS%2C%20S3%2C%20Secrets%20Encryption-%236C47FF?style=for-the-badge&logo=amazonaws&logoColor=white)
![CloudWatch](https://img.shields.io/badge/CloudWatch-Metrics%20%7C%20Agent%20%7C%20Alarms-%239C27B0?style=for-the-badge&logo=amazoncloudwatch&logoColor=white)
![Auto Scaling](https://img.shields.io/badge/Auto%20Scaling-Launch%20Template%20%7C%20CloudWatch%20Driven-%23FF9900?style=for-the-badge&logo=awsautoscaling&logoColor=white)
![Load Balancer](https://img.shields.io/badge/ALB-HTTPS%20Termination%20%7C%20Routing-%23007C9D?style=for-the-badge&logo=loadbalancer&logoColor=white)
![ACM](https://img.shields.io/badge/ACM-SSL%20Certificates%20%7C%20HTTPS%20Ingress-%23004C97?style=for-the-badge&logo=amazonaws&logoColor=white)
![Route 53](https://img.shields.io/badge/Route%2053-ALB%20DNS%20Alias%20Record-%23217AC0?style=for-the-badge&logo=amazonroute53&logoColor=white)

## Configuration

### 1. Clone the Repository

```sh
$ git clone <repository_url>
$ cd <repository_name>
```

### 2. Update Variables

Modify the `variables.tf` file or create a `terraform.tfvars` file to define your infrastructure settings.

### 3. Initialize Terraform

Run the following command to initialize Terraform and download required provider plugins:

```sh
$ terraform init
```

### 4. Plan Infrastructure Deployment

To preview the changes Terraform will make, run:

```sh
$ terraform plan
```

### 5. Apply Infrastructure Deployment

To create the AWS resources, run:

```sh
$ terraform apply
```

Terraform will prompt for confirmation before proceeding. Type `yes` to continue.

### 6. Verify Deployment

Once the infrastructure is created, Terraform will output the VPC ID, subnet IDs and S3 bucket:

```sh
$ terraform output
```

### 7. Destroy Infrastructure (Optional)

If you need to remove all deployed resources, run:

```sh
$ terraform destroy
```

Terraform will prompt for confirmation before deletion.

## `🔐 Import SSL/TLS Certificate into ACM`

If you are using a third-party SSL certificate (such as from Namecheap or GoDaddy) for HTTPS, you need to import it into AWS Certificate Manager (ACM).

To do this, run the following command using the AWS CLI:

```
aws acm import-certificate \
  --certificate fileb://<your-certificate>.crt \
  --private-key fileb://<your-private-key>.key \
  --certificate-chain fileb://<your-certificate-chain>.ca-bundle \
  --region <your-region>
```

Replace the placeholders with your actual file names and AWS region:

* **your-certificate.crt** is your SSL certificate file.
* **your-private-key.key** is the private key used when generating the CSR.
* **your-certificate-chain.ca-bundle** includes the intermediate certificates.
* **<your-region>** is the AWS region where you want to use the certificate (e.g., **us-east-1**).

After importing the certificate, update the **acm\_certificate\_arn** variable in your **terraform.tfvars** file or in Secrets Manager so it can be used in the HTTPS listener configuration.

## Notes

- Ensure your AWS credentials are correctly configured before running Terraform.
- Adjust CIDR blocks and other configurations according to your network requirements.
- If using different AWS profiles, update `aws_profile` accordingly.
