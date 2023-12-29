#!/bin/bash
set -e

# Install shiny-server dependencies (Ubuntu packages)
apt update && apt install -y cmake git xz-utils
apt install --reinstall libc6

SHINY_SERVER_VERSION=${1:-${SHINY_SERVER_VERSION:-latest}}

## build ARGs
NCPUS=${NCPUS:--1}

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install \
    sudo \
    gdebi-core \
    lsb-release \
    libcurl4-openssl-dev \
    libcairo2-dev \
    libxt-dev \
    xtail \
    wget

# Run dependency scripts
/rocker_scripts/install_s6init.sh
/rocker_scripts/install_pandoc.sh

# Install Shiny server

# if [ "$SHINY_SERVER_VERSION" = "latest" ]; then
#     SHINY_SERVER_VERSION=$(wget -qO- https://download3.rstudio.org/ubuntu-18.04/x86_64/VERSION)
# fi

# wget --no-verbose "https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb" -O ss-latest.deb
# gdebi -n ss-latest.deb
# rm ss-latest.deb

# Clone the repository from GitHub
cd /home
git clone https://github.com/rstudio/shiny-server.git

# Get into a temporary directory in which we'll build the project
cd shiny-server
mkdir tmp
cd tmp

# Install our private copy of Node.js
../external/node/install-node.sh

# Add the bin directory to the path so we can reference node
DIR=`pwd`
PATH=$DIR/../bin:$PATH

# Use cmake to prepare the make step. Modify the "--DCMAKE_INSTALL_PREFIX"
# if you wish the install the software at a different location.
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../
# Get an error here? Check the "How do I set the cmake Python version?" question below

# Compile native code and install npm dependencies
make
mkdir ../build
(cd .. && ./bin/npm install)

# Install the software at the predefined location
make install

# Install default config file
mkdir -p /etc/shiny-server
cp ../config/default.config /etc/shiny-server/shiny-server.conf

# Post installation steps (Shiny Server)
# Place a shortcut to the shiny-server executable in /usr/bin
sudo ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server

# Create shiny user. On some systems, you may need to specify the full path to 'useradd'
sudo useradd -r -m shiny

# Create log, config, and application directories
sudo mkdir -p /srv/shiny-server
sudo mkdir -p /var/lib/shiny-server
sudo mkdir -p /etc/shiny-server

# Get R packages
install2.r --error --skipinstalled -n "$NCPUS" shiny rmarkdown

# Set up directories and permissions
if [ -x "$(command -v rstudio-server)" ]; then
    DEFAULT_USER=${DEFAULT_USER:-rstudio}
    adduser "${DEFAULT_USER}" shiny
fi

cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/
chown shiny:shiny /var/lib/shiny-server
mkdir -p /var/log/shiny-server
chown shiny:shiny /var/log/shiny-server

# create init scripts
mkdir -p /etc/services.d/shiny-server
cat <<"EOF" >/etc/services.d/shiny-server/run
#!/usr/bin/with-contenv bash
## load /etc/environment vars first:
for line in $( cat /etc/environment ) ; do export $line > /dev/null; done
if [ "$APPLICATION_LOGS_TO_STDOUT" != "false" ]; then
    exec xtail /var/log/shiny-server/ &
fi
exec shiny-server 2>&1
EOF
chmod +x /etc/services.d/shiny-server/run

# install init script
cp /rocker_scripts/init_set_env.sh /etc/cont-init.d/01_set_env

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed lybraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so
