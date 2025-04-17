#!/bin/bash

# Update the package lists
echo "Updating package lists..."
apt-get update || { echo "Failed to update package lists"; exit 1; }

# Upgrade the system
echo "Upgrading packages..."
apt-get upgrade -y || { echo "Failed to upgrade packages"; exit 1; }

# Install MySQL
echo "Installing MySQL..."
apt-get install mysql-server -y || { echo "Failed to install MySQL"; exit 1; }

# Create the database
DB_NAME="csye6225"
echo "Creating database ${DB_NAME}..."
mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" || { echo "Failed to create database ${DB_NAME}"; exit 1; }

# Check if the group exists, and create if it doesn't
echo "Creating new group 'appgroup' ..."
if ! getent group appgroup >/dev/null; then
    groupadd appgroup || { echo "Failed to create group"; exit 1; }
else
    echo "Group 'appgroup' already exists."
fi

# Check if the user exists, and create if it doesn't
echo "Creating new user 'appuser' ..."
if ! id -u appuser >/dev/null 2>&1; then
    useradd -m -g appgroup -s /bin/bash appuser || { echo "Failed to create user"; exit 1; }
else
    echo "User 'appuser' already exists."
fi

echo "Adding 'appuser' to 'appgroup'..."
useradd -m -g appgroup -s /bin/bash appuser

# Install unzip if not already installed
echo "Checking for unzip tool..."
apt-get install unzip -y || { echo "Failed to install unzip"; exit 1; }

# Unzip the application in /opt/csye6225 directory
echo "Setting up application directory..."
mkdir -p /opt/csye6225
unzip /tmp/webapp.zip -d /opt/csye6225 || { echo "Failed to unzip application"; exit 1; }

#Move the .env file from tmp to the new directory
echo "Moving env file to /opt/csye6225/webapp..."
mv /tmp/.env /opt/csye6225/webapp || { echo "Failed to move .env file"; exit 1; }

# Update the permissions of the folder and artifacts
echo "Updating permissions..."
chown -R appuser:appgroup /opt/csye6225
chmod -R 750 /opt/csye6225

echo "Setup completed successfully."
