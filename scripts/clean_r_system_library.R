#' Clean extra packages from the system R library
#'
#' This function identifies packages installed in the system R library that are
#' not part of R's built-in or recommended package set. These packages usually
#' have `Priority = NA` in `installed.packages()`.
#'
#' The intended use case is a macOS R framework installation where packages were
#' accidentally installed into:
#'
#' `/Library/Frameworks/R.framework/Resources/library`
#'
#' instead of the user library.
#'
#' By default, the function only checks and reports candidate packages. It does
#' not install or remove anything unless `check_only = FALSE`.
#'
#' @param sys_lib Character. Path to the system R library. Defaults to `.Library`.
#' @param user_lib Character. Path to the user R library. Defaults to
#'   `Sys.getenv("R_LIBS_USER")`.
#' @param check_only Logical. If `TRUE`, only reports packages that would be
#'   removed and optionally installed. No installation or removal is performed.
#'   Defaults to `TRUE`.
#' @param reinstall Logical. If `TRUE`, packages detected in `sys_lib` but not
#'   found in `user_lib` are installed into `user_lib` after removal from
#'   `sys_lib`. If `FALSE`, no package installation is performed. Defaults to
#'   `FALSE`.
#' @param repos Character vector. CRAN repository setting passed to
#'   `install.packages()` when `reinstall = TRUE`. Defaults to
#'   `getOption("repos")`.
#'
#' @return Invisibly returns a list with:
#'   \itemize{
#'     \item `sys_lib`: system library path
#'     \item `user_lib`: user library path
#'     \item `extra_pkgs`: packages detected in `sys_lib` with `Priority = NA`
#'     \item `already_in_user_lib`: detected packages already present in `user_lib`
#'     \item `to_install`: detected packages missing from `user_lib`
#'     \item `installed`: packages installed into `user_lib`
#'     \item `failed_install`: packages that could not be installed into `user_lib`
#'     \item `removed`: packages removed from `sys_lib`
#'     \item `still_in_sys_lib`: packages still present in `sys_lib` after removal
#'     \item `check_only`: value of `check_only`
#'     \item `reinstall`: value of `reinstall`
#'   }
#'
#' @details
#' The function does not remove packages with `Priority = "base"` or
#' `Priority = "recommended"`.
#'
#' If `check_only = FALSE`, all detected extra packages are removed from the
#' system library.
#'
#' If `reinstall = TRUE`, detected packages that are missing from the user
#' library are installed into `user_lib`.
#'
#' Administrative privileges may be required to remove packages from the system
#' library on macOS.
#'
#' @examples
#' \dontrun{
#' clean_system_r_library()
#' clean_system_r_library(check_only = FALSE)
#' clean_system_r_library(check_only = FALSE, reinstall = TRUE)
#' }
clean_system_r_library <- function(
  sys_lib = .Library,
  user_lib = Sys.getenv("R_LIBS_USER"),
  check_only = TRUE,
  reinstall = FALSE,
  repos = getOption("repos")
) {
  if (!dir.exists(sys_lib)) {
    stop("sys_lib bulunamadı: ", sys_lib)
  }

  if (is.na(user_lib) || user_lib == "") {
    stop("R_LIBS_USER tanımlı değil. user_lib argümanını elle verin.")
  }

  dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)

  if (!dir.exists(user_lib)) {
    stop("user_lib oluşturulamadı: ", user_lib)
  }

  sys_lib_real <- normalizePath(sys_lib, winslash = "/", mustWork = TRUE)
  user_lib_real <- normalizePath(user_lib, winslash = "/", mustWork = TRUE)

  cat("\nSystem library:\n")
  cat("  Path     : ", sys_lib, "\n", sep = "")
  cat("  Real path: ", sys_lib_real, "\n", sep = "")

  cat("\nUser library:\n")
  cat("  Path     : ", user_lib, "\n", sep = "")
  cat("  Real path: ", user_lib_real, "\n", sep = "")

  if (identical(sys_lib_real, user_lib_real)) {
    stop(
      "sys_lib ve user_lib aynı gerçek dizini gösteriyor. İşlem durduruldu.\n",
      "sys_lib: ", sys_lib_real, "\n",
      "user_lib: ", user_lib_real
    )
  }

  ip_sys <- installed.packages(lib.loc = sys_lib)

  if (!"Priority" %in% colnames(ip_sys)) {
    stop("installed.packages() çıktısında Priority kolonu bulunamadı.")
  }

  extra_pkgs <- rownames(ip_sys)[is.na(ip_sys[, "Priority"])]

  ip_user <- installed.packages(lib.loc = user_lib)
  user_pkgs <- rownames(ip_user)

  already_in_user_lib <- intersect(extra_pkgs, user_pkgs)
  to_install <- if (reinstall) {
    setdiff(extra_pkgs, user_pkgs)
  } else {
    character(0)
  }

  cat("\nSummary:\n")
  cat("  Extra packages in system library: ", length(extra_pkgs), "\n", sep = "")
  cat("  Already present in user library : ", length(already_in_user_lib), "\n", sep = "")

  if (reinstall) {
    cat("  Missing in user library         : ", length(to_install), "\n", sep = "")
  }

  if (length(extra_pkgs) == 0) {
    cat("\nOK: Sistem library içinde silinecek ek paket bulunamadı.\n")

    return(invisible(list(
      sys_lib = sys_lib,
      user_lib = user_lib,
      extra_pkgs = character(0),
      already_in_user_lib = character(0),
      to_install = character(0),
      installed = character(0),
      failed_install = character(0),
      removed = character(0),
      still_in_sys_lib = character(0),
      check_only = check_only,
      reinstall = reinstall
    )))
  }

  cat("\nSistem library'den silinecek paketler:\n")
  print(extra_pkgs)

  if (check_only) {
    cat("\nCHECK ONLY: Hiçbir paket silinmedi veya kurulmadı.\n")

    if (reinstall && length(to_install) > 0) {
      cat("\nreinstall = TRUE olduğunda user library'ye kurulacak eksik paketler:\n")
      print(to_install)
    }

    return(invisible(list(
      sys_lib = sys_lib,
      user_lib = user_lib,
      extra_pkgs = extra_pkgs,
      already_in_user_lib = already_in_user_lib,
      to_install = to_install,
      installed = character(0),
      failed_install = character(0),
      removed = character(0),
      still_in_sys_lib = extra_pkgs,
      check_only = check_only,
      reinstall = reinstall
    )))
  }

  remove.packages(
    pkgs = extra_pkgs,
    lib = sys_lib
  )

  ip_sys_after <- installed.packages(lib.loc = sys_lib)
  still_in_sys_lib <- extra_pkgs[extra_pkgs %in% rownames(ip_sys_after)]
  removed <- setdiff(extra_pkgs, still_in_sys_lib)

  cat("\nRemoval status:\n")

  if (length(still_in_sys_lib) == 0) {
    cat("  OK: Sistem library'deki aday paketlerin tamamı silindi.\n")
  } else {
    cat("  UYARI: Bazı paketler sistem library'den silinemedi.\n")
    cat("\nSilinemeyen paketler:\n")
    print(still_in_sys_lib)
  }

  installed <- character(0)
  failed_install <- character(0)

  if (reinstall && length(to_install) > 0) {
    install.packages(
      pkgs = to_install,
      lib = user_lib,
      repos = repos,
      quiet = TRUE
    )

    ip_user_after <- installed.packages(lib.loc = user_lib)
    installed <- to_install[to_install %in% rownames(ip_user_after)]
    failed_install <- setdiff(to_install, installed)

    cat("\nInstallation status:\n")

    if (length(failed_install) == 0) {
      cat("  OK: Eksik paketlerin tamamı user library'ye kuruldu.\n")
    } else {
      cat("  UYARI: Bazı paketler user library'ye kurulamadı.\n")
      cat("\nKurulamayan paketler:\n")
      print(failed_install)
    }
  } else if (reinstall) {
    cat("\nInstallation status:\n")
    cat("  OK: User library'de eksik paket yok. Kurulum yapılmadı.\n")
  }

  invisible(list(
    sys_lib = sys_lib,
    user_lib = user_lib,
    extra_pkgs = extra_pkgs,
    already_in_user_lib = already_in_user_lib,
    to_install = to_install,
    installed = installed,
    failed_install = failed_install,
    removed = removed,
    still_in_sys_lib = still_in_sys_lib,
    check_only = check_only,
    reinstall = reinstall
  ))
}