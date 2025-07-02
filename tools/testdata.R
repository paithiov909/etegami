library(ggplot2)
library(dplyr)

cap <- ragg::agg_capture(width = 960, height = 540)
# ragg::agg_png("test.png", width = 1280, height = 720)

dplyr::slice_sample(starwars, prop = 1) |>
  ggplot(aes(x = mass, y = height, color = species)) +
  geom_point() +
  facet_wrap(~ gender)


rast <- cap(native = TRUE)
# rast <- fastpng::read_png("tools/plot.png", type = "nativeraster")
dev.off()

js <- jsonlite::toJSON(
  list(
    data_b64 = jsonlite::as_gzjson_b64(as.integer(rast)),
    width = dim(rast)[2],
    height = dim(rast)[1],
    id = "test"
  ),
  auto_unbox = TRUE
)

writeLines(js, "test4.json")
