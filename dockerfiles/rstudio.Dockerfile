# RStudio Server installation from rocker/rstudio.
ARG R_VERSION
ARG ARCH
ARG UBUNTU_VERSION

FROM dncr/r-base:${R_VERSION}-${ARCH}-${UBUNTU_VERSION}

ARG RSTUDIO_VERSION

ENV S6_VERSION=v2.1.0.2
ENV RSTUDIO_VERSION=${RSTUDIO_VERSION}
ENV DEFAULT_USER=rstudio
ENV PANDOC_VERSION=default
ENV QUARTO_VERSION=default

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
  libglpk-dev

# Ubuntu packages required for "R CMD check"
RUN apt-get update && apt-get install -y qpdf \
  ghostscript-x

# Install R packages for package developement
RUN R -e "install.packages('devtools')" && \
    R -e "install.packages('BiocManager')"

# Install Java and Reconfigure Java for R
RUN apt-get update && apt-get install -y default-jdk \
  default-jre
  
RUN R CMD javareconf -e

# Set "rstudio" password so that we can login
# Comment the next line if the password is set through Docker Compose file using "environment" variable
# RUN echo "rstudio:rstudio**" | chpasswd

# RStudio server runs on port 8787 by default.
EXPOSE 8787

CMD ["/init"]

