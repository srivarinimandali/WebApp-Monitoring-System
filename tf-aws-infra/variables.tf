variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
}

variable "vpc_id" {
  description = "Unique identifier for the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets"
  type        = number
}

variable "private_subnet_count" {
  description = "Number of private subnets"
  type        = number
}

variable "destination_cidr_block" {
  description = "CIDR block for public internet access"
  type        = string
}

variable "custom_ami_id" {
  description = "Custom AMI ID for EC2"
  type        = string
}

variable "application_port" {
  description = "Port for the application"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "allowed_cidr" {
  description = "Allowed CIDR blocks for security groups"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_protocol" {
  description = "Protocol for ingress rules"
  type        = string
  default     = "tcp"
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS"
  type        = number
  default     = 20
}

variable "db_storage_type" {
  description = "Storage type for RDS"
  type        = string
  default     = "gp2"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

variable "db_instance_identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
  default     = "csye6225"
}

variable "db_name" {
  description = "database name"
  type        = string
}

variable "rds_port" {
  description = "RDS database port"
  type        = number
  default     = 3306
}

variable "ec2_volume_size" {
  description = "EC2 root volume size in GB"
  type        = number
  default     = 25
}

variable "ec2_instance_name" {
  description = "EC2 instance name"
  type        = string
  default     = "webapp-instance"
}

variable "db_connection_params" {
  description = "Additional connection parameters for DB URL"
  type        = string
  default     = "useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
}
variable "db_parameter_group_family" {
  description = "RDS parameter group family"
  type        = string
  default     = "mysql8.0"
}
variable "hosted_zone_name" {
  description = "Name of the public hosted zone (dev.yourdomain.me)"
  type        = string
}
variable "launch_template_name" {
  description = "Name of the public hosted zone (dev.yourdomain.me)"
  type        = string
  default     = "csye6225_asg"
}
variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "webapp-asg"
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 3
}

variable "asg_min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 3
}

variable "asg_max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 5
}

variable "asg_cooldown" {
  description = "Cooldown period for the ASG in seconds"
  type        = number
  default     = 60
}

variable "asg_health_check_grace_period" {
  description = "Grace period for health checks"
  type        = number
  default     = 300
}
# --- Scale Up Policy ---
variable "scale_up_threshold" {
  description = "CPU utilization threshold to scale up"
  type        = number
  default     = 5
}

variable "scale_up_evaluation_periods" {
  description = "Number of periods for scale up alarm evaluation"
  type        = number
  default     = 2
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_up_cooldown" {
  description = "Cooldown time (in seconds) after scale up"
  type        = number
  default     = 60
}

# --- Scale Down Policy ---
variable "scale_down_threshold" {
  description = "CPU utilization threshold to scale down"
  type        = number
  default     = 3
}

variable "scale_down_evaluation_periods" {
  description = "Number of periods for scale down alarm evaluation"
  type        = number
  default     = 2
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down"
  type        = number
  default     = -1
}

variable "scale_down_cooldown" {
  description = "Cooldown time (in seconds) after scale down"
  type        = number
  default     = 60
}
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener in dev and demo"
  type        = string
}
