#!/bin/bash

# Referenced: https://pythonspeed.com/articles/system-packages-docker/
COPY install_zip.sh .
# Bash "strict mode", to help catch problems and bugs in the shell
set -euo pipefail

# Tell apt-get we're never going to be able to give manual feedback:
export DEBIAN_FRONTEND=noninteractive

# Update the package listing, so we know what package exist:
apt-get update

# Install security updates:
apt-get -y upgrade

# Install a new package, without unnecessary recommended packages:
apt-get -y install --no-install-recommends zip

# Delete cached files we don't need anymore
apt-get clean

# Delete index files we don't need anymore:
rm -rf /var/lib/apt/lists/*