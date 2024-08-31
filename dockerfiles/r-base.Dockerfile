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

# Import values of ARGs from ENVIRONMENT
ENV R_VERSION=${R_VERSION:-latest}
ENV R_HOME=${R_HOME:-/usr/local/lib/R}
ENV TZ=${TZ:-Etc/UTC}
ENV CRAN=${CRAN:-https://p3m.dev/cran/__linux__/${UBUNTU_VERSION:-jammy}/latest}
ENV LANG=${LANG:-en_US.UTF-8}

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh

COPY scripts /rocker_scripts
RUN /rocker_scripts/setup_R.sh

CMD ["R"]
