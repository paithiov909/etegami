# nolint start: object_name_linter

#' An S7 class for managing raster capture and viewer interaction
#'
#' `Postino` objects manage the capture of `nativeRaster` images, saving them as JSON,
#' and controlling a browser-based viewer interface. For usage, see [setup()].
#'
#' @details
#' These methods are available for `Postino` objects:
#'
#' * `shutdown(x, ...)`: Stops the viewer's HTTP server, if it is running. And also, this always calls [grDevices::dev.off()] internally.
#' * `post(x, ...)`: Captures a raster image using the associated graphics device and saves it as a JSON file.
#' * `lst(x, ...)`: Lists saved JSON files.
#' * `clear(x, ...)`: Deletes all saved JSON files.
#' * `browse(x, ..., delay = 10000, strip_base_url = FALSE)`: Launches the viewer in a web browser to display saved frames as a slideshow.
#'
#' @export
Postino <- new_class(
  "Postino",
  properties = list(
    out_dir = class_character,
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
#' @param x Postino instance.
#' @param ... Not used.
#' @rdname Postino
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
#' @param x Postino instance.
#' @param ... Not used.
#' @rdname Postino
#' @export
post <- new_generic("post", "x")
method(post, Postino) <- function(x, ...) {
  rast <- x@capture_device(native = TRUE)
  idx <- x@id_counter()
  path <- file.path(x@out_dir, paste0(idx, ".json"))
  write_nrjson(rast, idx, path)
  if (identical(x@mode, "live")) {
    browse(x, idx)
  }
  invisible(basename(path))
}

#' List saved frames
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @rdname Postino
#' @export
lst <- new_generic("lst", "x")
method(lst, Postino) <- function(x, ...) {
  list.files(x@out_dir, pattern = ".json")
}

#' Clear all saved frames
#'
#' @param x Postino instance.
#' @param ... Not used.
#' @rdname Postino
#' @export
clear <- new_generic("clear", "x")
method(clear, Postino) <- function(x, ...) {
  fs::file_delete(list.files(x@out_dir, pattern = ".json", full.names = TRUE))
  invisible(NULL)
}

#' Browse saved frames
#'
#' @param x Postino instance.
#' @param ... Files to browse.
#' @param delay Slide delay in milliseconds.
#' @param strip_base_url If `TRUE`, remove the base URL from the file paths.
#' Defaults to `FALSE`.
#' @rdname Postino
#' @export
browse <- new_generic("browse", "x", function(x, ..., delay = 1e3, strip_base_url = FALSE) {
  S7_dispatch()
})
method(browse, Postino) <- function(x, ..., delay = 1e3, strip_base_url = FALSE) {
  delay <- as.integer(delay)
  if (!is.finite(delay)) rlang::abort("`delay` is invalid.")

  files <- c(...)
  files[!grepl(".json$", files)] <- paste0(files[!grepl(".json$", files)], ".json")
  files <- files[files %in% lst(x)]
  if (rlang::is_empty(files)) {
    rlang::abort("No files to browse!")
  }

  baseurl <- if (strip_base_url) "" else x@server_config[["url"]]
  ids <- paste0(fs::path_ext_remove(files), collapse = ",")
  url <- paste0(baseurl, "?id=", ids, "&delay=", delay)
  if (!strip_base_url && interactive()) {
    utils::browseURL(url)
  }
  invisible(url)
}

# nolint end
