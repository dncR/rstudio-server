#!/bin/bash
set -e

apt update && apt install -y texlive \
  texlive-fonts-recommended \
  texlive-fonts-extra

#apt-get update && apt-get -y install texlive-base \
#  texlive-latex-base \
#  texlive-latex-extra \
#  texinfo \
#  texlive-fonts-recommended \
#  texlive-fonts-extra

updmap-user

