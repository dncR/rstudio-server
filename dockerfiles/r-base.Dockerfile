# Define BUILD args.
ARG UBUNTU_VERSION
ARG DOCKER_HUB_REPO

FROM ${DOCKER_HUB_REPO:-ubuntu}:${UBUNTU_VERSION:-jammy}

ARG UBUNTU_VERSION
ARG R_VERSION
ARG R_HOME
ARG TZ
ARG CRAN
ARG LANG
ARG DEBIAN_FRONTEND

# Import values of ARGs from ENVIRONMENT
ENV R_VERSION=${R_VERSION:-latest}
ENV R_HOME=${R_HOME:-/usr/local/lib/R}
ENV TZ=${TZ:-Etc/UTC}
ENV CRAN=${CRAN:-https://p3m.dev/cran/__linux__/${UBUNTU_VERSION:-jammy}/latest}
ENV LANG=${LANG:-en_US.UTF-8}
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}

# Ubuntu packages not included in "install_R_source.sh" or "setup_R.sh"
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libxml2-dev

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

COPY scripts /rocker_scripts

# RUN /rocker_scripts/setup_R.sh
RUN <<EOF
if grep -q "1000" /etc/passwd; then
    userdel --remove "$(id -un 1000)";
fi
/rocker_scripts/setup_R.sh
EOF

CMD ["R"]
