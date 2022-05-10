# RStudio Server installation from rocker/rstudio.
FROM dncr/rstudio-server:4.2.0-texlive

# Working directory within container.
WORKDIR /home/rstudio/
COPY ./scripts /home/rstudio/docker_scripts
RUN chmod -R +rwx /home/rstudio/docker_scripts/

# Install R libraries
RUN R -e "source('/home/rstudio/docker_scripts/installeR_YZKurs.R')"

# Remove scripts folder
RUN rm -fr /home/rstudio/docker_scripts

# RStudio server runs on port 8787 by default.
EXPOSE 8787

CMD ["/init"]

