terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
# Fetch account ID for policy interpolation
data "aws_caller_identity" "current" {}

# Fetch available AZs dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# Fetch Hosted Zone
data "aws_route53_zone" "subdomain_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

# VPC and Networking Resources
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.vpc_name}-${var.vpc_id}"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW-${var.vpc_name}-${var.vpc_id}"
  }
}
# Calculate Public and Private Subnet CIDR Blocks
locals {
  public_subnet_cidrs  = [for i in range(var.public_subnet_count) : cidrsubnet(var.vpc_cidr, 8, i + 1)]
  private_subnet_cidrs = [for i in range(var.private_subnet_count) : cidrsubnet(var.vpc_cidr, 8, i + var.public_subnet_count + 1)]
}
# Create Public Subnets
resource "aws_subnet" "public_subnets" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-${var.vpc_id}-Public-${count.index}"
  }
}
# Create Private Subnets
resource "aws_subnet" "private_subnets" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${var.vpc_name}-${var.vpc_id}-Private-${count.index}"
  }
}
# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Public-RT-${var.vpc_name}-${var.vpc_id}"
  }
}
# Create Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.igw.id
}
# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_assoc" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Private-RT-${var.vpc_name}-${var.vpc_id}"
  }
}
# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_assoc" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
# Security Groups
# Security Group for Application Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = var.ingress_protocol
    cidr_blocks = var.allowed_cidr
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = var.ingress_protocol
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr
  }

  tags = {
    Name = "load-balancer-sg"
  }
}
# Security Group for Web Application
resource "aws_security_group" "app_sg" {
  name        = "app-security-group"
  description = "Security group for web application"
  vpc_id      = aws_vpc.main.id

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = var.ingress_protocol
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow App access ONLY from Load Balancer SG
  ingress {
    from_port       = var.application_port
    to_port         = var.application_port
    protocol        = var.ingress_protocol
    security_groups = [aws_security_group.lb_sg.id]
    description     = "Allow traffic from Load Balancer SG only"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_cidr
  }

  tags = {
    Name = "app-security-group"
  }
}
# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS to allow MySQL traffic only from app security group"
  vpc_id      = aws_vpc.main.id

  # Allow MySQL connections (port 3306) only from EC2 instance security group
  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # Only allow access from app_sg
  }

  # Allow all outbound traffic within VPC
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr] # Restrict to only within VPC
  }

  tags = {
    Name = "rds-security-group"
  }
}
# KMS Resources
# KMS Key for EC2
resource "aws_kms_key" "ec2_kms" {
  description             = "KMS key for EC2 root volumes"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-ec2-policy",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 and AutoScaling services to use the key",
        Effect = "Allow",
        Principal = {
          Service = ["ec2.amazonaws.com", "autoscaling.amazonaws.com"]
        },
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncrypt*"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow ASG Service Role to use the key",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        },
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:ReEncrypt*"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 instance role to use the key",
        Effect = "Allow",
        Principal = {
          AWS = aws_iam_role.ec2_s3_role.arn
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "ec2-kms-key"
  }
}
#KMS Key for RDS
resource "aws_kms_key" "rds_kms" {
  description             = "KMS key for RDS instance"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-rds-policy",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow RDS to use the key",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "rds-kms-key"
  }
}
# KMS Key for S3
resource "aws_kms_key" "s3_kms" {
  description             = "KMS key for S3 bucket encryption"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-s3-policy",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow S3 to use the key",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "s3-kms-key"
  }
}
# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets_kms" {
  description             = "KMS key for encrypting secrets"
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "key-secrets-policy",
    Statement = [
      {
        Sid    = "Allow account root full access",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to use the key",
        Effect = "Allow",
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "secrets-kms-key"
  }
}
# KMS Aliases for better identification
resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-encryption-key"
  target_key_id = aws_kms_key.ec2_kms.key_id
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-encryption-key"
  target_key_id = aws_kms_key.rds_kms.key_id
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-encryption-key"
  target_key_id = aws_kms_key.s3_kms.key_id
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-encryption-key"
  target_key_id = aws_kms_key.secrets_kms.key_id
}
# IAM Resources
# EC2 IAM Role with S3 and KMS access
resource "aws_iam_role" "ec2_s3_role" {
  name = "EC2-S3-Access-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "EC2-S3-Access-Role"
  }
}
# IAM Policy for S3 Access
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Allow EC2 to access S3 for file upload and retrieval"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.webapp_bucket.id}/*"
        ]
      }
    ]
  })
}
# IAM Policy for Secrets Manager Access
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "SecretsAccessPolicy"
  description = "Allow EC2 to read RDS DB password secret"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = aws_secretsmanager_secret.rds_db_password_secret.arn
      }
    ]
  })
}
# Comprehensive EC2 KMS policy
resource "aws_iam_policy" "ec2_kms_access_policy" {
  name        = "EC2KMSAccessPolicy"
  description = "Allow EC2 to use KMS keys"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        Resource : [
          aws_kms_key.ec2_kms.arn,
          aws_kms_key.s3_kms.arn,
          aws_kms_key.secrets_kms.arn
        ]
      }
    ]
  })
}
# Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-Instance-Profile"
  role = aws_iam_role.ec2_s3_role.name
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.ec2_s3_role.name
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  policy_arn = aws_iam_policy.secrets_access_policy.arn
  role       = aws_iam_role.ec2_s3_role.name
}
resource "aws_iam_role_policy_attachment" "attach_kms_policy" {
  policy_arn = aws_iam_policy.ec2_kms_access_policy.arn
  role       = aws_iam_role.ec2_s3_role.name
}
# S3 Resources
# S3 Bucket for web application
resource "aws_s3_bucket" "webapp_bucket" {
  bucket        = uuid()
  force_destroy = true # Allows Terraform to delete the bucket even if not empty

  tags = {
    Name = "webapp-bucket"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "webapp_bucket_block" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "webapp_bucket_versioning" {
  bucket = aws_s3_bucket.webapp_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "webapp_bucket_encryption" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
  }
}
# Set lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "webapp_bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    id     = "move_to_standard_ia"
    status = "Enabled"

    filter {
      prefix = "" # Apply to all objects in the bucket
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
# RDS Resources
# Custom RDS Parameter Group for MySQL 8.0
resource "aws_db_parameter_group" "rds_param_group" {
  name        = "custom-mysql-8-0-parameter-group"
  family      = var.db_parameter_group_family
  description = "Custom parameter group for MySQL 8.0 RDS instance"

  parameter {
    name         = "max_connections"
    value        = "200"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_bin_trust_function_creators"
    value        = "1"
    apply_method = "immediate"
  }

  tags = {
    Name = "rds-custom-param-group-mysql8.0"
  }
}
# RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "rds-subnet-group"
  }
}

# Generate a random DB password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # Exclude /, @, ", and space
}
# Store the DB password in Secrets Manager
resource "aws_secretsmanager_secret" "rds_db_password_secret" {
  name                    = "rds-db-password"
  kms_key_id              = aws_kms_key.secrets_kms.arn
  recovery_window_in_days = 0

  tags = {
    Name = "rds-db-password"
  }
}

# Secret value for RDS password
resource "aws_secretsmanager_secret_version" "rds_db_password_secret_value" {
  secret_id     = aws_secretsmanager_secret.rds_db_password_secret.id
  secret_string = random_password.db_password.result
}
#RDS Instance
resource "aws_db_instance" "rds_instance" {
  identifier             = var.db_instance_identifier
  engine                 = "mysql"
  engine_version         = "8.0.35" # Ensure it matches MySQL 8.0
  instance_class         = var.db_instance_type
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_kms.arn
  multi_az               = var.db_multi_az
  publicly_accessible    = false # Ensure RDS is private
  db_name                = var.db_name
  username               = var.db_username
  password               = aws_secretsmanager_secret_version.rds_db_password_secret_value.secret_string
  parameter_group_name   = aws_db_parameter_group.rds_param_group.name
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Skip snapshot to avoid manual approval on destroy
  skip_final_snapshot = true

  tags = {
    Name = "csye6225-rds"
  }
}
# LoadBalancing and Auto Scaling Resources
# Target Group for Application
resource "aws_lb_target_group" "app_tg" {
  name     = "webapp-tg"
  port     = var.application_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "webapp-target-group"
  }
}
# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name = "webapp-alb"
  }
}
# Listener on Port 443 for HTTPS
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name = "dev-https-listener"
  }
}
# Launch Template for Auto Scaling Group
resource "aws_launch_template" "web_app_lt" {
  name          = var.launch_template_name
  image_id      = var.custom_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring {
    enabled = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  credit_specification {
    cpu_credits = "unlimited"
  }

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.ec2_volume_size
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ec2_kms.arn
    }
  }

  user_data = base64encode(<<EOF
#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "==> User data started..."

# Wait for IAM Role to propagate
sleep 5

# Fetch DB password securely
DB_PASSWORD=$(aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id rds-db-password --query SecretString --output text)

# Create /opt/app directory
mkdir -p /opt/app

# Write .env securely
cat <<EOT > /opt/app/.env
DB_URL=jdbc:mysql://${aws_db_instance.rds_instance.address}:${var.rds_port}/${var.db_name}?${var.db_connection_params}
DB_USERNAME=${var.db_username}
DB_PASSWORD=$DB_PASSWORD
AWS_S3_BUCKET_NAME=${aws_s3_bucket.webapp_bucket.id}
AWS_REGION=${var.aws_region}
EOT

chown csye6225:csye6225 /opt/app/.env
chmod 640 /opt/app/.env

echo "==> .env updated with credentials from Secrets Manager"

# Start CloudWatch Agent with config
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json \
  -s

# Enable CloudWatch Agent on boot and start now
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

echo "==> CloudWatch Agent configured and running."

# Start app
systemctl daemon-reload
systemctl restart webapp.service

echo "==> Web application started."
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.ec2_instance_name
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_app_asg" {
  name                      = var.asg_name
  desired_capacity          = var.asg_desired_capacity
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  default_cooldown          = var.asg_cooldown
  vpc_zone_identifier       = aws_subnet.public_subnets[*].id
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_health_check_grace_period

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.web_app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.ec2_instance_name
    propagate_at_launch = true
  }
}

# Scale Up Policy
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale-up-policy"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

# Scale Down Policy
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale-down-policy"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "cpu-utilization-scale-up"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.scale_up_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_up_threshold
  alarm_description   = "Scale up if average CPU > ${var.scale_up_threshold}%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "cpu-utilization-scale-down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.scale_down_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_down_threshold
  alarm_description   = "Scale down if average CPU < ${var.scale_down_threshold}%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
}
# DNS Configuration

# A Record for Load Balancer Alias
resource "aws_route53_record" "alb_alias_record" {
  zone_id = data.aws_route53_zone.subdomain_zone.zone_id
  name    = var.hosted_zone_name
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
