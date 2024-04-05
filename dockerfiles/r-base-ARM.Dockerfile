FROM arm64v8/ubuntu:jammy

# Define BUILD args.
ARG R_VERSION
ARG R_HOME
ARG TZ
ARG CRAN
ARG LANG

# Import values of ARGs from ENVIRONMENT
ENV R_VERSION=${R_VERSION}
ENV R_HOME=${R_HOME}
ENV TZ=${TZ}
ENV CRAN=${CRAN}
ENV LANG=${LANG}

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh
RUN /rocker_scripts/install_R_source.sh
COPY scripts /rocker_scripts
RUN /rocker_scripts/setup_R.sh

CMD ["R"]
