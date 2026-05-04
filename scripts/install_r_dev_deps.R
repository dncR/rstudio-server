packages <- c("devtools", "BiocManager", "remotes", "languageserver")

r_site_libs <- path.expand(.Library.site)
r_site_libs <- r_site_libs[nzchar(r_site_libs)]

if (length(r_site_libs) == 0) {
    r_site_libs <- path.expand(file.path(R.home(), "site-library"))
    message(".Library.site is not set; falling back to ", r_site_libs)
}

r_site_lib <- r_site_libs[[1]]

if (!dir.exists(r_site_lib)) {
    dir.create(r_site_lib, recursive = TRUE, showWarnings = FALSE)
}

if (!dir.exists(r_site_lib)) {
    stop("R site library could not be created: ", r_site_lib)
}

if (file.access(r_site_lib, 2) != 0) {
    stop("R site library is not writable: ", r_site_lib)
}

.libPaths(unique(c(r_site_lib, .libPaths())))

install.packages(
    packages,
    lib = r_site_lib,
    repos = "https://cran.r-project.org"
)

installed <- rownames(installed.packages(lib.loc = r_site_lib))
missing <- setdiff(packages, installed)

if (length(missing) > 0) {
    stop(
        "R development packages were not installed into ",
        r_site_lib,
        ": ",
        paste(missing, collapse = ", ")
    )
}
