#' Read a nativeRaster JSON file
#'
#' Loads a JSON file that encodes a nativeRaster object and restores it
#' as an R `nativeRaster`.
#'
#' @param path Path to the JSON file.
#' @returns A `nativeRaster` object with `id` attribute.
#' @export
read_nrjson <- function(path) {
  obj <- jsonlite::fromJSON(path, flatten = TRUE)
  rast <- jsonlite::parse_gzjson_b64(obj$data_b64)
  attr(rast, "id") <- obj$id
  dim(rast) <- c(obj$height, obj$width)
  class(rast) <- "nativeRaster"
  rast
}

#' Write a nativeRaster object to JSON
#'
#' Encodes a `nativeRaster` object as JSON and saves it to disk.
#' The file can be viewed in a compatible browser viewer.
#'
#' @param x A `nativeRaster` object.
#' @param id A string identifier for the image.
#' @param path File path to write to. Defaults to `paste0(id, ".json")`.
#' @returns The `path` is invisibly returned.
#' @export
write_nrjson <- function(x, id, path = paste0(id, ".json")) {
  if (!inherits(x, "nativeRaster")) rlang::abort("`x` must be a nativeRaster object")
  obj <- jsonlite::toJSON(
    list(
      data_b64 = jsonlite::as_gzjson_b64(as.integer(x)),
      width = dim(x)[2],
      height = dim(x)[1],
      id = id
    ),
    auto_unbox = TRUE
  )
  writeLines(obj, path)
  invisible(path)
}
