# INSTALL DOCKER ENGINE
# 1. Update the apt package index and install packages to allow apt to use a repository over HTTPS:
apt-get update
apt-get install \
  ca-certificates \
  curl \
  gnupg

# 2. Add Docker’s official GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Use the following command to set up the repository:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
# 4. Install Docker Engine
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# POST INSTALLATION STEPS
# 1. Create the docker group.
groupadd docker

# 2. Add your user to the docker group.
usermod -aG docker $USER


# INSTALL DOCKER COMPOSE (STANDALONE)
# 1. To download and install Compose standalone, run:
curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

# 2. Apply executable permissions to the standalone binary in the target path for the installation.
chmod +x /usr/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

