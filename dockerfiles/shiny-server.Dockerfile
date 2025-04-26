# Shiny Server installation
ARG R_VERSION
ARG UBUNTU_VERSION

FROM dncr/r-base:${R_VERSION:-latest}-${UBUNTU_VERSION:-jammy}

ARG UBUNTU_VERSION
ARG R_VERSION
ARG R_HOME
ARG TZ
ARG LANG
ARG DEBIAN_FRONTEND
ARG SHINY_SERVER_VERSION

# Import values of ARGs from ENVIRONMENT
ENV R_VERSION=${R_VERSION:-latest}
ENV R_HOME=${R_HOME:-/usr/local/lib/R}
ENV TZ=${TZ:-Etc/UTC}
ENV CRAN=${CRAN:-https://p3m.dev/cran/__linux__/${UBUNTU_VERSION:-jammy}/latest}
ENV LANG=${LANG:-en_US.UTF-8}
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND:-noninteractive}

ENV S6_VERSION="v2.1.0.2"
ENV PANDOC_VERSION="default"
ENV SHINY_SERVER_VERSION=${SHINY_SERVER_VERSION:-latest}

COPY scripts /rocker_scripts

RUN /rocker_scripts/install_shiny_server.sh

EXPOSE 3838

CMD ["/init"]