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
setup_assets <- function(out_dir) {
  assets <- system.file("dist", package = "etegami", mustWork = TRUE)
  out_dir <- file.path(out_dir, paste0("Postino-", time_stamp()))
  fs::dir_create(out_dir)
  fs::dir_copy(assets, out_dir, overwrite = TRUE)
}

#' Initialize a Postino instance and launch viewer server
#'
#' Sets up a new subdirectory including viewer assets, starts a local server,
#' and returns a `Postino` instance for managing raster output and display.
#' `setup()` initializes a new graphics device via [ragg::agg_capture()]
#' and starts a local HTTP server in the background using [servr::httd()].
#'
#' @param out_dir Output directory where viewer assets are copied into.
#' Defaults to a temporary directory.
#' @param capture_device A function that returns a `nativeRaster` object.
#' @param id_counter A function to generate frame IDs.
#' @param mode Viewer mode. Either `"batch"` or `"live"`.
#' If `"live"` mode, the viewer will automatically launch
#' every time `post()` is called.
#' @param ... Additional arguments passed to [servr::httd()].
#' @returns A `Postino` object.
#' @export
setup <- function(
  out_dir = tempdir(),
  capture_device = ragg::agg_capture(width = 720, height = 576),
  id_counter = counter(),
  mode = c("batch", "live"),
  ...
) {
  mode <- rlang::arg_match(mode)
  serve_dir <- setup_assets(out_dir)
  config <- servr::httd(serve_dir, browser = FALSE, ...) ## This returns a 'server_config' (list).
  Postino(
    serve_dir = serve_dir,
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
      base::plot(x, , ...)
    } else {
      base::plot(x, y, ...)
    }
    invisible(post(postino))
  }
}
