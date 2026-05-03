# SSH Remote Docker: R and renv Notes

These notes explain the startup chain between `renv` and the VS Code R integration when connecting over SSH to a Docker container running on a local machine and using R through VS Code / Antigravity.

The purpose of this document is to separate two different topics:

- `renv` library / lockfile problems
- VS Code R session attach / `.vsc.attach()` problems

These two issues can appear at the same time, but they are not the same problem.

## Target Scenario

- Host: local machine
- Remote: Docker container
- Connection: SSH Remote
- Editor: VS Code / Antigravity
- R usage type:
  - regular R folder
  - project folder using `renv`

## Main Problem

Helper functions required by the VS Code R integration, such as `.vsc.attach()`, are created only when the correct startup chain runs.

Typical error:

```r
.vsc.attach()
Error in .vsc.attach() : could not find function ".vsc.attach"
```

This error usually happens for one of these reasons:

- the R session was opened outside the VS Code terminal
- `~/.Rprofile` was not loaded at all
- the project-root `.Rprofile` shadowed the home `~/.Rprofile`
- the `renv` project startup flow left the editor init chain incomplete

## Diagnostic Result: What Is the Real Difference?

In this scenario, the main difference is not directly the difference between `macOS` and `Ubuntu`. The real difference is which startup chain opened the R session.

The diagnostic findings are:

- if the project-root `.Rprofile` contains only `source("renv/activate.R")`, the home `~/.Rprofile` usually does not run automatically
- `renv/activate.R` does not separately source the user profile while the autoloader is active
- the home `~/.Rprofile` sources `~/.vscode-R/init.R`
- this init chain sometimes does not directly create the `.vsc.attach` function; instead, it prepares the `.First.sys()` hook
- your home `~/.Rprofile` completes the attach chain when needed with the `try(.First.sys(), silent = TRUE)` fallback
- when the project `.Rprofile` does not source the home `~/.Rprofile`, this fallback never runs

Short conclusion:

- the plain `renv` startup chain alone is not always sufficient
- the VS Code bootstrap and fallback logic inside the home `~/.Rprofile` plays a critical role in the remote container scenario
- therefore, conditionally sourcing the home `~/.Rprofile` from the `.Rprofile` inside the `renv` project is a practical and safe solution

## Important Note About `.Rprofile` Loading Order

A common but incorrect assumption is:

1. first `~/.Rprofile`
2. then the `.Rprofile` in the project directory

In practice, if there is an `.Rprofile` in the project root, startup behavior is not this simple. In `renv` projects, the project `.Rprofile` often effectively takes over the active startup chain, and the home `~/.Rprofile` may not be processed automatically.

Therefore, if this file:

```r
source("renv/activate.R")
```

is used by itself, the VS Code startup settings under the home directory may never run.

## Recommended `~/.Rprofile` for the Home Directory

This variant is a safe startup configuration for the SSH remote + Docker + VS Code / Antigravity scenario:

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

### Logic of This Block

- it runs only in interactive R sessions
- it runs only in the VS Code terminal
- it does not run inside RStudio
- it does not run inside Positron
- it loads the `~/.vscode-R/init.R` chain
- it completes the attach hook with a fallback when that hook is incomplete in remote/container sessions

## Regular R Folder Scenario

If the project does not contain `renv`:

- `~/.Rprofile` is usually enough
- open the R terminal from inside VS Code
- do not use `R --vanilla`

Check:

```r
exists(".vsc.attach")
search()
```

Expected:

- `exists(".vsc.attach")` -> `TRUE`
- `tools:vscode` appears in `search()`

## `renv` Project Scenario

In `renv` projects, there is usually an `.Rprofile` in the project root. This file often contains only the following line:

```r
source("renv/activate.R")
```

This is not sufficient by itself, because:

- `renv` becomes active
- project library paths are configured
- but the VS Code bootstrap chain and `.First.sys()` fallback in the home `~/.Rprofile` may never run

## Recommended Project `.Rprofile`

The safest practical solution is to conditionally source the home `~/.Rprofile` from the project `.Rprofile` after activating `renv`.

Recommended variant:

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

### Why Prefer the Conditional Block?

An unconditional variant:

```r
if (file.exists("~/.Rprofile")) {
  source("~/.Rprofile")
}
```

works in many cases, but it has a broader impact.

The conditional block is better because:

- it runs only in interactive sessions
- it runs only when `TERM_PROGRAM == "vscode"`
- it avoids unnecessary side effects in other flows such as RStudio / Positron / batch / `Rscript` / CI
- it helps separate the project `renv` configuration from editor bootstrap logic

Short decision:

- in a closed remote container setup that belongs only to you and is used only for VS Code, the unconditional variant can also be acceptable
- for a general and reusable standard, prefer the conditional block

## Why Should the Order Be `renv` Then `~/.Rprofile`?

Recommended order:

1. first, `renv` sets up the project library environment
2. then the VS Code / Antigravity integration is loaded
3. when needed, the `.First.sys()` fallback inside the home `~/.Rprofile` completes the attach chain

With this order:

- project libraries become active
- the editor watcher can see the required functions
- both `renv` and the editor integration work in the same session

## `RENV_CONFIG_EXTERNAL_LIBRARIES` Note

The following setting is useful in this scenario:

```text
RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library
```

For example, inside `~/.Renviron`:

```text
RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library
```

The purpose of this setting is to:

- make site-library packages visible while under `renv`
- make it easier to access packages such as `jsonlite`, `rlang`, and `httpgd` that may be needed by the editor chain or helper tools

But this setting does not guarantee:

- that `~/.Rprofile` runs
- that the `~/.vscode-R/init.R` chain is sourced
- that the `.vsc.attach()` function is created automatically

In other words, this variable reduces package visibility problems; by itself, it does not solve startup chain problems.

## The `renv` Warning and the `.vsc.attach()` Error Are Not the Same Thing

A message like this:

```text
One or more packages recorded in the lockfile are not installed.
Use `renv::status()` for more details.
```

is a separate problem. It means the lockfile and installed packages do not match.

This message is not the direct cause of this error:

```r
.vsc.attach()
Error in .vsc.attach() : could not find function ".vsc.attach"
```

The first is `renv` status information; the second is a startup / editor integration problem.

## Quick Diagnostic Flow

Run the following checks inside R:

```r
interactive()
Sys.getenv("TERM_PROGRAM")
Sys.getenv("RSTUDIO")
Sys.getenv("POSITRON")
Sys.getenv("R_PROFILE_USER")
exists(".vsc.attach")
exists(".First.sys")
search()
.libPaths()
requireNamespace("jsonlite", quietly = TRUE)
requireNamespace("rlang", quietly = TRUE)
```

Interpretation:

- `interactive()` should be `TRUE`
- `TERM_PROGRAM == "vscode"` should be true
- `exists(".vsc.attach")` should be `TRUE`
- `tools:vscode` should appear in `search()`
- `jsonlite` and `rlang` should be visible

If:

- `TERM_PROGRAM == "vscode"` is correct
- `jsonlite` and `rlang` are visible
- but `.vsc.attach == FALSE`

then the problem is most likely not a missing package, but an incomplete startup chain.

## Typical Behavior Combinations

### Case 1: Regular Folder + `~/.Rprofile`

Expected:

- `tools:vscode` is attached
- `.vsc.attach` is found

### Case 2: `renv` Project + Only `source("renv/activate.R")`

Expected risk:

- `renv` becomes active
- `renv:shims` appears
- but `.vsc.attach` may be missing

### Case 3: `renv` Project + Conditional `source("~/.Rprofile")`

Expected result:

- `renv` becomes active
- the home profile chain runs
- when needed, the `.First.sys()` fallback completes the attach
- `tools:vscode` appears

## Fixing `renv` Problems

Inside R:

```r
renv::status()
renv::restore()
```

If needed:

```r
renv::diagnostics()
renv::repair()
```

Note:

- `renv::restore()` targets lockfile mismatches
- `renv::repair()` can help with cache / symlink corruption
- these commands do not automatically solve attach chain problems

## Things to Avoid

- do not put `rm(list = ls())` in `~/.Rprofile`
- do not force a plain shell session opened outside VS Code to behave like a VS Code session
- if there is a project `.Rprofile`, do not assume that `~/.Rprofile` will automatically run anyway
- remember that sessions opened with `R --vanilla` have different profile behavior
- do not assume that `RENV_CONFIG_EXTERNAL_LIBRARIES` solves the attach problem by itself
- do not add unconditional `source("~/.Rprofile")` everywhere while ignoring possible side effects

## Recommended Standard

1. Keep a single reference `~/.Rprofile` under the home directory
2. In that file, include the logic to source `~/.vscode-R/init.R` and, when needed, run the `.First.sys()` fallback
3. In `renv` projects, add `source("renv/activate.R")` first in the project `.Rprofile`, then add the conditional home profile source block
4. Open the R terminal from inside VS Code / Antigravity
5. If needed, define `RENV_CONFIG_EXTERNAL_LIBRARIES=/usr/local/lib/R/site-library` inside `~/.Renviron`
6. Run `renv::restore()` for lockfile mismatches

## Practical Conclusion

In practice, the most robust approach in this scenario is:

- make the home `~/.Rprofile` the central place for the VS Code bootstrap
- add the conditional home profile source block as a standard snippet in the `renv` project `.Rprofile`
- evaluate startup chain problems separately from package visibility problems

## Short Summary

- in regular folders, `~/.Rprofile` is usually enough
- in `renv` projects, the project `.Rprofile` can shadow the home profile chain
- `RENV_CONFIG_EXTERNAL_LIBRARIES` is useful, but it does not solve the attach problem by itself
- in the remote Docker + SSH scenario, the critical point is making sure the VS Code bootstrap and `.First.sys()` fallback inside the home `~/.Rprofile` can run
- therefore, adding a conditional `source("~/.Rprofile")` block to the `renv` project `.Rprofile` is the most practical standard solution
