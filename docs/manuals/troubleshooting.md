# Common Issues and Solutions

## Purpose and Scope

This document records recurring issues encountered in R, radian, VS Code, Remote SSH, Docker, `renv`, and the development workflows in this repository.

Each entry should clearly describe how the problem appears, the likely source, the recommended fix, and whether the fix has been verified. The goal is to reduce diagnosis time when the same issue appears again and to make it clear which solution worked on which system.

Use the following fields for new issue entries when possible:

- Problem description
- Root cause
- Recommended fix
- Fix result
- Verified system

## radian Fails With `TRUELENGTH` After R Version Upgrade

### Problem Description

After removing one R version and installing a newer R version, the `radian` terminal failed before starting the R session. This case was tested during the R 4.5 to R 4.6 upgrade.

Observed error:

```text
Exception: Cannot load symbol TRUELENGTH: dlsym(..., TRUELENGTH): symbol not found
```

In the inspected environment, R was pointing to the expected version:

```text
R version: 4.6.0
R HOME: /Library/Frameworks/R.framework/Resources
radian version: 0.6.15
rchitect version: 0.4.8
```

### Root Cause

The error occurred before R startup files or project files were executed. Therefore, the problem was not caused by `.Rprofile`, `.Renviron`, `renv`, or repository settings. It was caused by an incompatibility between R 4.6.0 and the Python dependency `rchitect`, which is used by `radian`.

`rchitect` attempted to load the `TRUELENGTH` symbol from R's shared library. That symbol was not available in the `libR.dylib` provided by the R 4.6.0 installation, so `radian` could not start.

### Recommended Fix

Update the `radian` and `rchitect` packages using the same Python interpreter that runs the `radian` command:

```sh
python3 -m pip install --user -U radian rchitect
```

After updating, verify with:

```sh
radian --version
radian
```

The expected result is that the `radian` terminal reaches the R prompt without the startup error.

### Fix Result

This recommended fix was applied and worked. `radian` started working again with R 4.6.0.

### Verified System

- macOS
- Apple Silicon
- M3 MacBook Pro
- R 4.6.0
