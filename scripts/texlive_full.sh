set -e

apt-get update && apt-get install -y texlive-full

# Set character mapping for new fonts.
updmap-user
