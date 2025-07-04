# nolint start: object_name_linter

#' An S7 class for managing raster capture and viewer interaction
#'
#' `Postino` objects manage the capture of `nativeRaster` images, saving them as JSON,
#' and controlling a browser-based viewer interface. For usage, see [setup()].
#'
#' @param serve_dir Directory where JSON files are saved.
#' @param capture_device A graphics device function to use for capturing frames. See [ragg::agg_capture()].
#' @param id_counter A function to generate unique IDs for frames.
#' @param mode `"batch"` (default) or `"live"`.
#' @param server_config A list of configuration settings out of [servr::httd()].
#' @export
#' @examples
#' \dontrun{
#' # Instead of using `setup()`, you can create a Postino instance manually:
#' postino <- Postino(
#'   serve_dir = "Postino-dir",
#'   capture_device = ragg::agg_capture(),
#'   id_counter = counter(),
#'   mode = "batch",
#'   server_config = servr::httd("Postino-dir", browser = FALSE)
#' )
#' }
Postino <- new_class(
  "Postino",
  properties = list(
    serve_dir = class_character,
    capture_device = class_function,
    id_counter = class_function,
    mode = class_character,
    server_config = class_list
  ),
  validator = function(self) {
    if (self@mode != "batch" && self@mode != "live") {
      rlang::abort("`mode` must be 'batch' or 'live'")
    }
  }
)

#' Stop the httd server
#'
#' Stops the viewer's HTTP server, if it is running.
#' And also, this always calls [grDevices::dev.off()] internally.
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @family Postino-methods
#' @export
shutdown <- new_generic("shutdown", "x")
method(shutdown, Postino) <- function(x, ...) {
  if (is.function(x@server_config[["stop_server"]])) {
    x@server_config[["stop_server"]]()
  }
  grDevices::dev.off()
}

#' Capture and save a frame
#'
#' Captures a raster image using the associated graphics device and saves it as a JSON file.
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @returns The name of the saved JSON file.
#' @family Postino-methods
#' @export
post <- new_generic("post", "x")
method(post, Postino) <- function(x, ...) {
  rast <- x@capture_device(native = TRUE)
  idx <- x@id_counter()
  path <- file.path(x@serve_dir, paste0(idx, ".json"))
  write_nrjson(rast, idx, path)
  if (identical(x@mode, "live")) {
    browse(x, idx)
  }
  invisible(basename(path))
}

#' List saved frames
#'
#' Lists saved JSON files.
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @returns A character vector of file names.
#' @family Postino-methods
#' @export
lst <- new_generic("lst", "x")
method(lst, Postino) <- function(x, ...) {
  list.files(x@serve_dir, pattern = ".json")
}

#' Clear all saved frames
#'
#' Deletes all saved JSON files.
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @family Postino-methods
#' @export
clear <- new_generic("clear", "x")
method(clear, Postino) <- function(x, ...) {
  fs::file_delete(list.files(x@serve_dir, pattern = ".json", full.names = TRUE))
  invisible(NULL)
}

#' Browse saved frames
#'
#' Launches the viewer in a new browser window to display saved frames as a slideshow.
#'
#' @param x Postino instance.
#' @param ... Files to browse.
#' @param delay Slide delay in milliseconds.
#' @param baseurl Base URL for the viewer. If `NULL`, the stored URL is used.
#' @returns The viewer URL is invisibly returned.
#' @family Postino-methods
#' @export
browse <- new_generic("browse", "x", function(x, ..., delay = 1e3, baseurl = NULL) {
  S7_dispatch()
})
method(browse, Postino) <- function(x, ..., delay = 1e3, baseurl = NULL) {
  delay <- as.integer(delay)
  if (!is.finite(delay)) rlang::abort("`delay` is invalid.")

  files <- c(...)
  files[!grepl(".json$", files)] <- paste0(files[!grepl(".json$", files)], ".json")
  files <- files[files %in% lst(x)]
  if (rlang::is_empty(files)) {
    rlang::abort("No files to browse!")
  }

  baseurl <- baseurl %||% x@server_config[["url"]]
  ids <- paste0(fs::path_ext_remove(files), collapse = ",")
  url <- paste0(baseurl, "?id=", ids, "&delay=", delay)
  if (interactive()) {
    utils::browseURL(url)
  }
  invisible(url)
}

# nolint end
