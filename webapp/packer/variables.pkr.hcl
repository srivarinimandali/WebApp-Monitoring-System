variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_source_ami" {
  type    = string
  default = "ami-04b4f1a9cf54c11d0"
}

variable "aws_instance_type" {
  type    = string
  default = "t2.small"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}
# Image Naming Variables (Default Names)
variable "aws_ami_name_tag" {
  type    = string
  default = "webapp-ami"
}
variable "aws_ami_name" {
  type    = string
  default = "ami"
}

variable "gcp_image_name" {
  type    = string
  default = "webapp-image"
}

# Tagging Variables (Default Metadata)
variable "image_project_name" {
  type    = string
  default = "WebApp"
}

variable "image_created_by" {
  type    = string
  default = "Packer"
}
# GCP Variables
variable "gcp_project_id" {
  type    = string
  default = "development-451901"
}

variable "gcp_source_image" {
  type    = string
  default = "ubuntu-2404-noble-amd64-v20250214"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-b"
}

variable "gcp_machine_type" {
  type    = string
  default = "n1-standard-1"
}
variable "db_url" {
  type    = string
  default = "jdbc:mysql://localhost:3306/appdb"
}

variable "db_username" {
  type    = string
  default = "appdb"
}

variable "db_password" {
  type    = string
  default = "temppwd"
}