FROM arm64v8/ubuntu:jammy

ENV R_VERSION=4.3.2
ENV R_HOME=/usr/local/lib/R
ENV TZ=Etc/UTC

COPY scripts/install_R_source.sh /rocker_scripts/install_R_source.sh

RUN /rocker_scripts/install_R_source.sh

ENV CRAN=https://p3m.dev/cran/__linux__/jammy/latest
ENV LANG=en_US.UTF-8

COPY scripts /rocker_scripts

RUN /rocker_scripts/setup_R.sh

CMD ["R"]
