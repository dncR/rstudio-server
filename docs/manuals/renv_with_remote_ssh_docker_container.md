# R, renv, and VS Code over Remote SSH in a Docker Container

## Description

This manual describes a practical setup for using R and `renv` from VS Code over Remote SSH, where the remote environment is a Docker container.

The goal is to keep the R startup chain predictable in this scenario:

- Host machine connects to a Docker container by SSH Remote.
- VS Code starts the R session inside the container.
- The project may use `renv`.
- VS Code's R integration needs its startup helper functions, such as `.vsc.attach()`, to be available.

The key point is that a project-level `.Rprofile` used by `renv` can take over the startup flow. When that happens, the home-level `~/.Rprofile` may not run automatically, so VS Code's R initialization may be skipped unless it is sourced explicitly.

## Remote SSH Container Setup

Create or update the home-level R profile inside the remote container:

```sh
nano ~/.Rprofile
```

Recommended `~/.Rprofile` content:

```r
term_program <- tolower(Sys.getenv("TERM_PROGRAM", unset = ""))
is_vscode <- identical(term_program, "vscode")
is_positron <- nzchar(Sys.getenv("POSITRON")) || identical(term_program, "positron")
is_rstudio <- nzchar(Sys.getenv("RSTUDIO"))

if (interactive() && is_vscode && !is_positron && !is_rstudio) {
  vsc_init <- path.expand("~/.vscode-R/init.R")

  if (file.exists(vsc_init)) {
    source(vsc_init, local = globalenv())

    if (!exists(".vsc.attach", envir = globalenv(), inherits = FALSE) &&
        exists(".First.sys", envir = globalenv(), mode = "function", inherits = FALSE)) {
      try(.First.sys(), silent = TRUE)
    }
  }
}
```

This file is responsible for loading VS Code's R initialization logic when R is started from a VS Code terminal. It only runs in interactive VS Code sessions, avoids RStudio and Positron sessions, sources `~/.vscode-R/init.R`, and runs `.First.sys()` as a fallback when the VS Code attach function is not created immediately.

## renv Project `.Rprofile`

In an `renv` project, the project root usually contains its own `.Rprofile`. A minimal `renv` profile often looks like this:

```r
source("renv/activate.R")
```

For this Remote SSH Docker scenario, use the following project-level `.Rprofile` instead:

```r
source("renv/activate.R")

term_program <- tolower(Sys.getenv("TERM_PROGRAM", unset = ""))
is_vscode <- identical(term_program, "vscode")
is_positron <- nzchar(Sys.getenv("POSITRON")) || identical(term_program, "positron")
is_rstudio <- nzchar(Sys.getenv("RSTUDIO"))

if (interactive() && is_vscode && !is_positron && !is_rstudio && file.exists("~/.Rprofile")) {
  source("~/.Rprofile", local = globalenv())
}
```

The first line activates the project-specific `renv` environment. The conditional block then loads the home-level `~/.Rprofile` only for interactive VS Code sessions. This keeps `renv` active while still allowing VS Code's R bootstrap chain to run.

The order matters:

1. `renv` activates the project library.
2. The home-level `~/.Rprofile` loads the VS Code R integration.
3. VS Code helper functions become available in the same R session.

## Home `.Renviron` for renv External Libraries

Create or update the home-level R environment file inside the remote container:

```sh
nano ~/.Renviron
```

Example content for Ubuntu-based containers:

```text
RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library
```

This setting tells `renv` about an external R library path. In Ubuntu-based R images, `/usr/local/lib/R/site-library` is a common site-library location. This path is OS-specific and can be different on other Linux distributions or custom R images.

Use this setting when some packages are installed outside the project `renv` library but still need to be visible to R, VS Code helper tooling, or development workflows.

## VS Code Requirements

### Ubuntu System Libraries

Install the system libraries needed by several R packages used in VS Code R workflows:

```sh
sudo apt-get update
sudo apt-get install -y libuv1-dev cmake
```

These packages are commonly required while installing or compiling R packages used by VS Code's R integration.

### R Packages

Install the required R packages inside the remote container:

```r
install.packages(
  c("devtools", "remotes", "languageserver"),
  lib = "/usr/local/lib/R/site-library"
)
```

These packages can also be installed while `renv` is active. In that case, they are installed into the isolated project library managed by `renv`.

For packages that should be shared across multiple `renv` projects, the recommended approach is to install them while `renv` is not active and write them directly to the R site-library by passing the target library path through `lib`. On Ubuntu-based R images, `/usr/local/lib/R/site-library` is a common site-library path. Adjust this path if your image or operating system uses a different R site-library location.

`languageserver` provides language features used by VS Code. `devtools` and `remotes` are useful for installing and managing development packages, including packages from remote repositories.

### radian as the VS Code R Terminal

`radian` can be used as the R terminal backend in VS Code. The simplest installation path is through `pipx`.

Install `pipx` inside the remote container:

```sh
sudo apt-get update
sudo apt-get install -y pipx
```

Install `radian` for the remote user that will run R, for example the `rstudio` user:

```sh
pipx install radian
```

This usually creates the executable under the user's local binary directory, for example:

```text
/home/rstudio/.local/bin/radian
```

If `radian` also needs to be available for root, it can be installed for root separately:

```sh
sudo pipx install radian
```

To make the user-level `radian` executable available system-wide, create a symbolic link under `/usr/local/bin`:

```sh
sudo ln -sf /home/rstudio/.local/bin/radian /usr/local/bin/radian
sudo chmod +x /home/rstudio/.local/bin/radian
```

Adjust `/home/rstudio/.local/bin/radian` if `radian` was installed under a different remote user. The important point is that `/usr/local/bin/radian` should resolve to the executable inside the remote container.

Then configure VS Code to use `radian` as the R terminal. Add the following setting to the Remote SSH User Settings JSON, not the local user settings JSON:

```json
{
  "r.rterm.linux": "/home/rstudio/.local/bin/radian",
  "r.bracketedPaste": true,
  "r.rterm.option": [
    "--no-save",
    "--no-restore"
  ],
  "r.rpath.linux": "/usr/local/bin/R"
}
```

These settings should be placed in the Remote SSH settings because the paths belong to the Linux container, not the local machine. `r.rterm.linux` points VS Code to the user-level `radian` executable, `r.rpath.linux` points the extension to the container's R binary, `r.rterm.option` starts R without saving or restoring workspace state, and `r.bracketedPaste` improves multi-line paste behavior in the R terminal.

## Quick Check

Start R from the VS Code terminal connected to the container, then run:

```r
interactive()
Sys.getenv("TERM_PROGRAM")
exists(".vsc.attach")
search()
.libPaths()
```

Expected results:

- `interactive()` returns `TRUE`.
- `Sys.getenv("TERM_PROGRAM")` returns `vscode`.
- `exists(".vsc.attach")` returns `TRUE`.
- `tools:vscode` appears in `search()`.
- The active library paths include the project `renv` library and any configured external library path.
