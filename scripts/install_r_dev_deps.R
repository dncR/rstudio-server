r_libs_user <- path.expand(Sys.getenv("R_LIBS_USER"))

if (!nzchar(r_libs_user)) {
    stop("R_LIBS_USER is not set")
}

if (!dir.exists(r_libs_user)) {
    dir.create(r_libs_user, recursive = TRUE)
}

.libPaths(c(r_libs_user, .libPaths()))

install.packages(
    c("devtools", "BiocManager", "remotes", "languageserver"),
    lib = r_libs_user,
    repos = "https://cran.r-project.org"
)
