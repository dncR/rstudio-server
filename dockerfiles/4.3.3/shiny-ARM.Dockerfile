FROM dncr/r-base:4.3.3-ARM

ENV S6_VERSION=v2.1.0.2
ENV SHINY_SERVER_VERSION=latest
ENV PANDOC_VERSION=default

COPY scripts/install_shiny_server-ARM.sh /rocker_scripts/

RUN /rocker_scripts/install_shiny_server-ARM.sh

EXPOSE 3838

CMD ["/init"]
