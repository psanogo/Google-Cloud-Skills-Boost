#!/bin/bash

sudo -u ethereum bash <<'EOF'
bash

cd ~
sudo apt update -y
sudo apt-get update -y
sudo apt install -y dstat jq

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh

mkdir -p /mnt/disks/chaindata-disk/ethereum/geth/chaindata
mkdir -p /mnt/disks/chaindata-disk/ethereum/geth/logs
mkdir -p /mnt/disks/chaindata-disk/ethereum/lighthouse/chaindata
mkdir -p /mnt/disks/chaindata-disk/ethereum/lighthouse/logs

sudo add-apt-repository -y ppa:ethereum/ethereum
sudo apt-get -y install ethereum

geth version

# Fetch the latest release information from GitHub API
RELEASE_URL="https://api.github.com/repos/sigp/lighthouse/releases/latest"
LATEST_VERSION=$(curl -s $RELEASE_URL | jq -r '.tag_name')

# Download the latest release using curl
DOWNLOAD_URL=$(curl -s $RELEASE_URL | jq -r '.assets[] | select(.name | endswith("x86_64-unknown-linux-gnu.tar.gz")) | .browser_download_url')

curl -L "$DOWNLOAD_URL" -o "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

# Extract the tar file
tar -xvf "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

# Remove the tar file
rm "lighthouse-${LATEST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

sudo mv lighthouse /usr/bin
lighthouse --version

cd ~
mkdir ~/.secret
openssl rand -hex 32 > ~/.secret/jwtsecret
chmod 440 ~/.secret/jwtsecret
EOF
