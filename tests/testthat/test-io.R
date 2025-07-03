test_that("read and write does not change data", {
  nr <- system.file("extdata/testdata.json", package = "etegami")
  rast1 <- read_nrjson(nr)
  rast2 <- write_nrjson(rast1, id = "testdata", path = tempfile(fileext = ".json")) |>
    read_nrjson()
  expect_equal(rast1, rast2)
})
