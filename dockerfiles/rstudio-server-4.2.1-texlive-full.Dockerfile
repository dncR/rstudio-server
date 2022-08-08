# RStudio Server installation from rocker/rstudio.
FROM dncr/rstudio-server:4.2.1

# Working directory within container.
WORKDIR /home/rstudio/

# Copy scripts into container.
COPY ./scripts /home/rstudio/docker_scripts
RUN chmod -R +rwx /home/rstudio/docker_scripts/

# Base TeX installation
RUN sh ./docker_scripts/texlive_full.sh

# Set "rstudio" password so that we can login
# Comment the next line if the password is set through Docker Compose file using "environment" variable
# RUN echo "rstudio:rstudio**" | chpasswd

# Remove scripts folder
RUN rm -fr /home/rstudio/docker_scripts

# RStudio server runs on port 8787 by default.
EXPOSE 8787

CMD ["/init"]

