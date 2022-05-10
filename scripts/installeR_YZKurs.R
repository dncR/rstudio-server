# Common Packages
pkgs <- c("markdown", "rmarkdown", "dplyr", "magrittr", "caret", "ggplot2")
install.packages(pkgs)

# Class Imbalance - M. BASOL ----
# Packages to be installed.
pkgs.to.install <- c(
  "ROSE",
  "themis"
)

# Install CRAN packages
install.packages(pkgs.to.install)

# Install packages from GitHub repos.
remotes::install_github("cran/DMwR")
