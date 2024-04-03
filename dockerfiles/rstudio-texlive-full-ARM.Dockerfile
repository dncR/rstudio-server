# RStudio Server installation from rocker/rstudio.
FROM dncr/rstudio-server:4.3.3-ARM

# Working directory within container.
WORKDIR /home/rstudio/

# Base TeX installation
RUN sh /rocker_scripts/texlive_full.sh

# Set "rstudio" password so that we can login
# Comment the next line if the password is set through Docker Compose file using "environment" variable
# RUN echo "rstudio:rstudio**" | chpasswd

# RStudio server runs on port 8787 by default.
EXPOSE 8787

CMD ["/init"]

