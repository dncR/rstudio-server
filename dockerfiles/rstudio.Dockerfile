# RStudio Server installation
ARG R_VERSION
ARG UBUNTU_VERSION

FROM dncr/r-base:${R_VERSION:-latest}-${UBUNTU_VERSION:-jammy}

ARG RSTUDIO_VERSION
ARG PREINSTALL_R_PKG
ARG INSTALL_TEX

ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=${RSTUDIO_VERSION:-2024.04.2+764}
ENV DEFAULT_USER=rstudio
ENV PANDOC_VERSION=default
ENV QUARTO_VERSION=default

ENV LANG=${LANG:-en_US.UTF-8}

COPY scripts /rocker_scripts
RUN chmod 777 -R /rocker_scripts

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh

# Working directory within container.
WORKDIR /home/rstudio/

# Add opencpu user to sudoers
RUN adduser rstudio sudo

# Set permissions for R site-library
# This step enables rstudio-server to write into site-library folders.
RUN chown rstudio /usr/local/lib/R/site-library
RUN chmod -R +rwx /usr/local/lib/R/site-library

# Install ubuntu packages
# RUN apt-get update && apt-get install -y apt-utils
RUN apt-get update && apt-get install -y libz-dev \
  nano \
  librsvg2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libssh2-1-dev \
  libgdal-dev \
  libproj-dev \
  libgeos-dev \
  libglu1-mesa-dev \
  libgmp3-dev \
  libmpfr-dev \
  libgl-dev \
  libglpk-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libgit2-dev && \
  rm -rf /var/lib/apt/lists/*

# Install OpenSSH server for remote development access
RUN apt-get update && apt-get install -y openssh-server && \
  rm -rf /var/lib/apt/lists/*

# Configure SSH daemon and default authorized_keys location
RUN mkdir -p /var/run/sshd /home/rstudio/.ssh && \
  chown rstudio:rstudio /home/rstudio/.ssh && \
  chmod 700 /home/rstudio/.ssh && \
  sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config && \
  echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Manage sshd under s6 supervision
RUN mkdir -p /etc/services.d/ssh && \
  cat <<"EOF" >/etc/services.d/ssh/run
#!/usr/bin/with-contenv bash
exec /usr/sbin/sshd -D -e
EOF

# Ubuntu packages required for "R CMD check"
RUN apt-get update && apt-get install -y qpdf \
  ghostscript-x && \
  rm -rf /var/lib/apt/lists/*

# Preinstalled R packages for package developement
RUN /rocker_scripts/preinstall_r_packages.sh

# Tex Live Installation
RUN /rocker_scripts/texlive_full.sh

# Install Java and Reconfigure Java for R
RUN apt-get update && apt-get install -y default-jdk \
    default-jre && \
    rm -rf /var/lib/apt/lists/*
  
RUN R CMD javareconf -e

# Set LANG from locale.
RUN locale-gen ${LANG}

# RStudio server runs on port 8787 by default. SSH uses 22.
EXPOSE 22 8787

CMD ["/init"]
