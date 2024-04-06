# RStudio Server installation from rocker/rstudio.
ARG R_VERSION
ARG ARCH
ARG UBUNTU_VERSION

FROM dncr/rstudio-server:${R_VERSION}-${ARCH}-${UBUNTU_VERSION}

# Working directory within container.
WORKDIR /home/rstudio/

# Base TeX installation
RUN sh /rocker_scripts/texlive_full.sh

# Set LANG from locale.
RUN locale-gen en_US.UTF-8

# RStudio server runs on port 8787 by default.
EXPOSE 8787

CMD ["/init"]

