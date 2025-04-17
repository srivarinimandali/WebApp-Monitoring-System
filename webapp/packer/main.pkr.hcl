packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0, <2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    googlecompute = {
      version = ">= 1.0.0, <2.0.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "amazon-ebs" "aws_image" {
  ami_name      = "${var.aws_ami_name}-{{timestamp}}"
  region        = var.aws_region
  source_ami    = var.aws_source_ami
  instance_type = var.aws_instance_type
  ssh_username  = var.ssh_username

  tags = {
    "Name"      = "${var.aws_ami_name_tag}-{{timestamp}}"
    "Project"   = var.image_project_name
    "CreatedBy" = var.image_created_by
  }
}
# source "googlecompute" "gcp_image" {
#   project_id   = var.gcp_project_id
#   source_image = var.gcp_source_image
#   zone         = var.gcp_zone
#   machine_type = var.gcp_machine_type
#   image_name   = "${var.gcp_image_name}-{{timestamp}}"
#   ssh_username = var.ssh_username
# }
build {
  # sources = ["source.amazon-ebs.aws_image", "source.googlecompute.gcp_image"]
  sources = ["source.amazon-ebs.aws_image"]
  # Copy application JAR
  provisioner "file" {
    source      = "target/cloud-0.0.1-SNAPSHOT.jar"
    destination = "/tmp/cloud-0.0.1-SNAPSHOT.jar"
  }

  # Copy systemd service file
  provisioner "file" {
    source      = "packer/webapp.service"
    destination = "/tmp/webapp.service"
  }

  # Copy the install script
  provisioner "file" {
    source      = "packer/install-app.sh"
    destination = "/tmp/install_app.sh"
  }
  # Copy CloudWatch Agent configuration
  provisioner "file" {
    source      = "packer/cloudwatch-agent-config.json"
    destination = "/tmp/cloudwatch-agent-config.json"
  }
  # Create and configure `.env` file in `/opt/webapp`
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/app",
      "echo 'DB_URL=\"${var.db_url}\"' | sudo tee /opt/app/.env > /dev/null",
      "echo 'DB_USERNAME=\"${var.db_username}\"' | sudo tee -a /opt/app/.env > /dev/null",
      "echo 'DB_PASSWORD=\"${var.db_password}\"' | sudo tee -a /opt/app/.env > /dev/null",
      "sudo chmod 600 /opt/app/.env",
      "sudo chown root:root /opt/app/.env",
      "sudo chmod +x /tmp/install_app.sh",
      "sudo -E /tmp/install_app.sh"
    ]
  }
}
