#' Generate a counter function
#'
#' @returns A function that increments a counter and returns a formatted string.
#' @export
counter <- function() {
  local({
    count <- 0
    function(format = "%04d") {
      count <<- count + 1
      sprintf(format, count)
    }
  })
}

#' Generate a timestamp string
#'
#' Returns the current system time in `"%Y%m%d_%H%M%S"` format.
#'
#' @returns A character string representing the timestamp.
#' @keywords internal
time_stamp <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S")
}

#' @noRd
setup_assets <- function(dir) {
  assets <- system.file("dist", package = "etegami", mustWork = TRUE)
  dir <- file.path(dir, paste0("Postino-", time_stamp()))
  fs::dir_create(dir)
  fs::dir_copy(assets, dir, overwrite = TRUE)
}

#' Initialize a Postino instance and launch viewer server
#'
#' Sets up a temporary directory, copies viewer assets, starts a local server,
#' and returns a `Postino` instance for managing raster output and display.
#'
#' @note
#' Note that calling `setup()` open a new graphics device via [ragg::agg_capture()]
#' and launch a local HTTP server in the background using [servr::httd()].
#'
#' @param out_dir Output directory. Defaults to a temporary directory.
#' @param capture_device A function that returns a `nativeRaster` object.
#' @param id_counter A function to generate frame IDs.
#' Defaults to [time_stamp()].
#' @param mode Viewer mode. Either `"batch"` or `"live"`.
#' If `"live"` mode, the viewer will automatically launch
#' every time `post()` is called.
#' @param ... Additional arguments passed to [servr::httd()].
#' @returns A `Postino` object.
#' @export
setup <- function(
  out_dir = tempdir(),
  capture_device = ragg::agg_capture(),
  id_counter = counter(),
  mode = c("batch", "live"),
  ...
) {
  mode <- rlang::arg_match(mode)
  out_dir <- setup_assets(out_dir)
  config <- servr::httd(out_dir, browser = FALSE, ...) ## This returns a 'server_config' (list).
  Postino(
    out_dir = out_dir,
    capture_device = capture_device,
    id_counter = id_counter,
    mode = mode,
    server_config = config
  )
}

#' Wrap the base plot function to auto-capture frames
#'
#' Returns a plotting function that behaves like [base::plot()]
#' but also captures the result using a [Postino] instance.
#'
#' @param postino A [Postino] object used to capture and save frames.
#' @returns A function compatible with `plot()` that also triggers capture.
#' @export
mask_plot <- function(postino) {
  force(postino)
  function(x, y, ...) {
    if (missing(y)) {
      base::plot(x, ...)
    } else {
      base::plot(x, y, ...)
    }
    invisible(post(postino))
  }
}
