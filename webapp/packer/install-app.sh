#!/bin/bash
set -e

echo "Starting application installation..."

# Check and install AWS CLI using official installer if not present
if ! command -v aws &>/dev/null; then
  echo "AWS CLI not found, installing..."
  sudo apt-get update
  sudo apt-get install -y unzip curl
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws
fi

# Re-check AWS CLI presence and fail if still not available
if ! command -v aws &>/dev/null; then
  echo "Error: AWS CLI installation failed. Exiting."
  exit 1
fi

# Ensure required environment variables are set
if [[ ! -f "/opt/app/.env" ]]; then
  echo "Warning: Configuration file /opt/app/.env not found. Creating..."
  touch /opt/app/.env
fi

# Load environment variables
set -o allexport
source /opt/app/.env
set +o allexport

if [[ -z "$DB_USERNAME" || -z "$DB_PASSWORD" || -z "$DB_URL" ]]; then
  echo "Error: DB_USERNAME, DB_PASSWORD, and DB_URL must be set."
  exit 1
fi

echo "Updating package list and installing dependencies..."
sudo apt-get update
sudo apt-get install -y openjdk-21-jre-headless

# Secure the environment file
sudo chmod 600 /opt/app/.env
sudo chown root:root /opt/app/.env

# Ensure the application user exists
if ! id "csye6225" &>/dev/null; then
  echo "Creating system user csye6225..."
  sudo groupadd -r csye6225 || true
  sudo useradd -r -g csye6225 -s /usr/sbin/nologin csye6225 || true
fi

# Create and secure application directory
echo "Setting up application directory..."
sudo mkdir -p /opt/app
sudo cp /tmp/cloud-0.0.1-SNAPSHOT.jar /opt/app/

# Set ownership and permissions
sudo chown -R csye6225:csye6225 /opt/app
sudo chmod -R 750 /opt/app

# Configure systemd service
echo "Configuring systemd service..."
sudo cp /tmp/webapp.service /etc/systemd/system/webapp.service
sudo systemctl daemon-reload
sudo systemctl enable webapp.service
sudo systemctl restart webapp.service

# Verify if the application started successfully
if ! sudo systemctl is-active --quiet webapp.service; then
  echo "Error: Web application failed to start."
  journalctl -u webapp.service --no-pager --since "5 minutes ago"
  exit 1
fi

echo "Installation complete and web application is running!"

echo "Installing Amazon CloudWatch Agent..."

# Install CloudWatch Agent
sudo apt-get update
sudo apt-get install -y wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i amazon-cloudwatch-agent.deb

# Create config directory
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/

# Copy config file during packer build
sudo cp /tmp/cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json

echo "CloudWatch Agent installation and config copy completed."