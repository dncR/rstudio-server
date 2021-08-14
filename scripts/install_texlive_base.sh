#!/bin/bash
set -e

apt-get update && apt-get -y install texlive-base \
  texlive-latex-base \
  texlive-latex-extra \
  texinfo
