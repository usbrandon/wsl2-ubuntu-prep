#!/bin/bash

# Check for the existence of the deadsnakes PPA
if ! grep -q "^deb .*/deadsnakes/ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "The deadsnakes PPA is not present. Adding it now..."
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get update
else
    echo "The deadsnakes PPA is already present."
fi

# Check if python3.11 is installed
dpkg -l | grep -qw python3.11 || {
    echo "Python3.11 is not installed. Would you like to install it? (y/n)"
    read -r answer
    if [ "$answer" == "y" ]; then
        sudo apt-get install -y python3.11
    else
        echo "Python3.11 will not be installed."
    fi
}

# Check for additional Python packages
echo "Do you want to install additional Python 3.11 packages (python3.11-dev, python3.11-venv, etc.)? (y/n)"
read -r answer
if [ "$answer" == "y" ]; then
    sudo apt install python3.11-dev python3.11-venv python3.11-distutils python3.11-gdbm python3.11-tk python3.11-lib2to3 -y
else
    echo "Additional Python 3.11 packages will not be installed."
fi


# Check if python3 is installed
dpkg -l | grep -qw python3 || {
    echo "Python3 is not installed. Would you like to install it? (y/n)"
    read -r answer
    if [ "$answer" == "y" ]; then
        sudo apt-get update
        sudo apt-get install -y python3
    else
        echo "Python3 will not be installed."
    fi
}

# Check if python3-venv is installed
dpkg -l | grep -qw python3-venv || {
    echo "Python3-venv is not installed. Would you like to install it? (y/n)"
    read -r answer
    if [ "$answer" == "y" ]; then
        sudo apt-get install -y python3-venv
    else
        echo "Python3-venv will not be installed."
    fi
}

echo "Finished checking and installing packages."

# Dynamically update default Python version
echo "Updating the default Python version..."

# Get all python versions available in /usr/bin/
python_versions=$(ls /usr/bin/python* | grep -Po '(?<=python)\d\.\d+' | sort -uV)

# Initialize priority
priority=1

# Loop through each version and update alternatives
for version in $python_versions; do
    if [ -f "/usr/bin/python$version" ]; then
        echo "Adding Python $version to update-alternatives with priority $priority"
        sudo update-alternatives --install /usr/bin/python python /usr/bin/python$version $priority
        priority=$((priority + 1))
    fi
done

# Create and activate a Python virtual environment
VENV_DIR="$HOME/ansible_venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# Check if ansible is installed
if ! pip show ansible > /dev/null 2>&1; then
    echo "Ansible is not installed. Installing the latest version..."
    pip install ansible
else
    echo "Ansible is already installed. Do you want to upgrade to the latest version? (y/n)"
    read -r answer
    if [ "$answer" == "y" ]; then
        pip install --upgrade ansible
    else
        echo "Ansible will not be upgraded."
    fi
fi

echo "Finished checking and installing Ansible."

if ! aws --version 2>&1 | grep -q "aws-cli/2"; then
    echo "AWS CLI v2 is not installed. Installing it now..."

    # Download the AWS CLI v2 installer
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    # Unzip the installer
    unzip awscliv2.zip

    # Install AWS CLI v2
    sudo ./aws/install

    # Clean up
    rm -rf aws awscliv2.zip
else
    echo "AWS CLI v2 is already installed."
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Installing it now..."

    # Add the HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Add the HashiCorp APT repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Update the APT package list and install Terraform
    sudo apt update && sudo apt install -y terraform
else
    echo "Terraform is already installed."
fi

echo "Finished checking and installing required tools."
