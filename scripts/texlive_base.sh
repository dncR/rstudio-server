set -e

apt-get update && apt-get install -y texlive-base \
  texlive-latex-base \
  texlive-fonts-recommended \
  texlive-fonts-extra

# Map installed fonts for the current user
updmap-user