## usethis namespace: start
#' @import S7
#' @keywords internal
## usethis namespace: end
"_PACKAGE"

#' @noRd
.onLoad <- function(...) {
  S7::methods_register()
}
