# Saving/restoring R Sessions with renv

This note describes how to save and restore the package environment for this
project with `renv`. In this context, `renv` does not save live R objects from
memory; it records and restores package versions through `renv.lock`.

## 1. Activate renv

Run these commands from the project root.

```r
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

renv::activate(project = ".")
```

Restart the R session after activation if `renv` asks you to do so.

## 2. Save the package state with cache enabled

This is the default `renv` behavior. Packages are installed into the project
library as links to the global `renv` cache when possible.

```r
renv::settings$use.cache(TRUE, project = ".")

renv::snapshot(
  project = ".",
  lockfile = "renv.lock",
  prompt = FALSE
)
```

Use this when you want faster installs and shared package storage across
projects.

## 3. Save the package state without using cache

Use this if you want packages to be stored directly inside the project library
instead of relying on the global `renv` cache.

```r
renv::settings$use.cache(FALSE, project = ".")
options(renv.config.cache.enabled = FALSE)

renv::snapshot(
  project = ".",
  lockfile = "renv.lock",
  prompt = FALSE
)
```

This changes how packages are stored and restored, not what is written to
`renv.lock`.

## 4. Restore packages from renv.lock

Run this from the project root after cloning or reopening the project.

```r
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

renv::activate(project = ".")
```

Restart R if needed, then restore:

```r
renv::restore(
  project = ".",
  lockfile = "renv.lock",
  prompt = FALSE
)
```

For a stricter restore that removes packages not recorded in `renv.lock`:

```r
renv::restore(
  project = ".",
  lockfile = "renv.lock",
  clean = TRUE,
  prompt = FALSE
)
```

## 5. Restore without using cache

Disable cache before restoring.

```r
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

renv::activate(project = ".")
renv::settings$use.cache(FALSE, project = ".")
options(renv.config.cache.enabled = FALSE)

renv::restore(
  project = ".",
  lockfile = "renv.lock",
  clean = TRUE,
  rebuild = TRUE,
  prompt = FALSE
)
```

`rebuild = TRUE` forces packages to be rebuilt instead of reused from an
existing installed copy.

## 6. Copy compatible packages from existing libraries

Before restoring, you may want to reuse compatible packages that are already
installed in external R libraries such as the user library or system library.
`renv::hydrate()` can copy matching packages into the project library.

```r
renv::hydrate(
  project = ".",
  library = renv::paths$library(project = "."),
  sources = .libPaths(),
  update = FALSE,
  prompt = FALSE
)
```

This can reduce download and build time. It does not replace
`renv::restore()`: after hydrating, still run restore so that the project
library is checked against `renv.lock`.

```r
renv::restore(
  project = ".",
  lockfile = "renv.lock",
  clean = TRUE,
  prompt = FALSE
)
```

When cache is disabled, hydrating is useful if you want compatible packages to
be copied directly into the project library instead of linked from the global
`renv` cache.

## 7. Check environment status

After snapshot or restore, check whether the project library and lockfile are in
sync.

```r
renv::status(project = ".")
```

If the active R version differs from the R version recorded in `renv.lock`,
`renv` may warn you. Native packages, especially Bioconductor packages, can fail
to compile or load when the R and Bioconductor versions do not match the
lockfile.
