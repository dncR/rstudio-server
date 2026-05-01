# RStudio Server installation
ARG R_VERSION
ARG UBUNTU_VERSION

FROM dncr/r-base:${R_VERSION:-latest}-${UBUNTU_VERSION:-noble}

ARG RSTUDIO_VERSION
ARG DEFAULT_USER=rstudio
ARG R_DEV_DEPS
ARG TEX
ARG JAVA
ARG SSH

ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=${RSTUDIO_VERSION:-2026.04.0+526}
ENV DEFAULT_USER=${DEFAULT_USER}
ENV PANDOC_VERSION=default
ENV QUARTO_VERSION=default

ENV LANG=${LANG:-en_US.UTF-8}

COPY scripts /rocker_scripts
RUN find /rocker_scripts -type d -exec chmod 755 {} + && \
  find /rocker_scripts -type f -exec chmod 644 {} + && \
  find /rocker_scripts -type f \( -name "*.sh" -o -name "*.R" -o -name "*.r" \) -exec chmod 755 {} +

RUN BUILD_IMAGE=rstudio /rocker_scripts/build_metadata.sh init rstudio

RUN /rocker_scripts/install_rstudio.sh
RUN /rocker_scripts/install_pandoc.sh
RUN /rocker_scripts/install_quarto.sh

# Working directory within container.
WORKDIR /home/${DEFAULT_USER}/

# Keep sudo access opt-in at container runtime instead of baking it into
# the image. When ROOT=true is provided at startup, init_userconf.sh adds the
# runtime user to the sudo group and enables passwordless sudo. If build-time
# sudo access is intentionally required for every image, uncomment the command
# below and use usermod to avoid depending on the optional adduser package.
# RUN usermod -aG sudo ${DEFAULT_USER}

# Allow RStudio users in the staff group to install/update site-library packages
# without making the library world-writable.
RUN /rocker_scripts/fix_r_site_library_permissions.sh

# Optional Java installation and R Java configuration. This runs before R
# package installation because R_DEV_DEPS=true forces Java on.
RUN BUILD_IMAGE=rstudio /rocker_scripts/install_java.sh

# Optional R package development dependencies and preinstalled R packages.
RUN BUILD_IMAGE=rstudio /rocker_scripts/install_r_dev_deps.sh && \
  /rocker_scripts/fix_r_site_library_permissions.sh

# Optional TeX Live installation.
RUN BUILD_IMAGE=rstudio /rocker_scripts/install_texlive_variant.sh

# Optional OpenSSH server for remote development access.
RUN BUILD_IMAGE=rstudio /rocker_scripts/install_ssh.sh

# Set LANG from locale.
RUN locale-gen ${LANG}

# RStudio Server uses port 8787. SSH uses port 22 when SSH=true.
EXPOSE 22 8787

CMD ["/init"]
