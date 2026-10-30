test_that("hourly and irregular timestamps", {
  t0 <- as.POSIXct("2024-03-01 00:00:00", tz = "UTC")
  d <- data.frame(who = rep(c("a", "b"), each = 48), t = rep(t0 + 3600 * 0:47, 2), y = rnorm(96))
  p <- as_panel(d, who, t)
  expect_equal(panel_meta(p)$freq, "hour")
  expect_equal(nrow(panel_aggregate(p, "y", period = "day")), 2)
  expect_s3_class(panel_line(p, "y"), "ggplot")
  txt <- d; txt$t <- format(txt$t, "%Y-%m-%d %H:%M:%S")
  expect_equal(panel_meta(as_panel(txt, who, t))$freq, "hour")
  irr <- data.frame(who = "a", t = t0 + c(0, 1000, 5000, 90000), y = 1:4)
  q <- as_panel(irr, who, t)
  expect_error(panel_aggregate(q, "y"), "irregular")
  expect_equal(nrow(panel_aggregate(q, "y", period = "day")), 2)
})

test_that("wide panels pivot, with and without measure stubs", {
  w <- data.frame(id = 1:3, inc80 = 1:3, inc81 = 2:4, ue80 = 0, ue81 = 1)
  p <- as_panel_wide(w, id, cols = -id, names_pattern = "^(inc|ue)(\\d+)$")
  expect_true(all(c("inc", "ue") %in% names(p)))
  expect_equal(panel_meta(p)$n_periods, 2)
  w2 <- data.frame(id = 1:2, `2001` = 1:2, `2002` = 3:4, check.names = FALSE)
  expect_equal(panel_meta(as_panel_wide(w2, id, cols = -id, values_to = "v"))$kind, "year")
})

d <- data.frame(who = rep(1:6, each = 5), yr = rep(2001:2005, 6),
                g = rep(c("x", "y", NA), each = 10), a = rep(1:6, each = 5) + 0.5, b = 2, c = 1)
p <- as_panel(d, who, yr)

test_that("missing groups become a labelled group; period = 'all' collapses time", {
  t <- panel_aggregate(p, "a", by = "g")
  expect_true("(missing)" %in% t$g)
  expect_equal(nrow(panel_aggregate(p, "a", by = "g", period = "all")), 3)
})

test_that("every chart type builds and tables round-trip", {
  expect_s3_class(panel_tracking(p, "a"), "ggplot")
  expect_s3_class(panel_band(p, "a", by = "g"), "ggplot")
  expect_s3_class(panel_bar(p, "a", by = "g"), "ggplot")
  expect_s3_class(panel_stacked(p, c("a", "b", "c"), by = "g"), "ggplot")
  expect_s3_class(panel_distribution(p, "a", by = "g"), "ggplot")
  expect_s3_class(panel_line(p, "a", by = "g", highlight = "x", index = TRUE, log = TRUE), "ggplot")
  expect_s3_class(panel_plot(p, "a", kind = "bar", by = "g"), "ggplot")
  tr <- panel_tracking(p, "a", window = 2, return = "table")
  expect_equal(nrow(tr), 10)
  expect_equal(panel_line(p, "a", by = "g", index = TRUE, return = "table")$a[1], 100)
})

test_that("line labels tolerate missing endpoints and whole missing groups", {
  d <- data.frame(id = rep(1:3, each = 3), t = rep(2001:2003, 3),
                  g = rep(c("a", "b", "c"), each = 3),
                  y = c(1, 2, NA, 2, 3, 4, NA, NA, NA))
  chart <- panel_line(as_panel(d, id, t), "y", by = "g")
  labels <- chart$layers[[2]]$data
  expect_equal(labels$.group, c("a", "b"))
  expect_equal(labels$y, c(2, 4))
  expect_true(all(is.finite(labels$.y)))
  expect_s3_class(ggplot2::ggplot_build(chart), "ggplot_built")
})

test_that("line labels stay separated when groups have tied endpoints", {
  d <- data.frame(id = rep(1:2, each = 2), t = rep(2001:2002, 2),
                  g = rep(c("Alpha", "Beta"), each = 2), y = c(1, 3, 2, 3))
  chart <- panel_line(as_panel(d, id, t), "y", by = "g")
  labels <- chart$layers[[2]]$data
  expect_lt(labels$.y[1], labels$.y[2])
  expect_equal(mean(labels$.y), 3)
})

test_that("spaghetti sampling is reproducible and leaves RNG state unchanged", {
  q <- as_panel(data.frame(id = rep(1:20, each = 2), t = rep(1:2, 20), y = 1:40), id, t)
  set.seed(42)
  old <- .Random.seed
  a <- panel_spaghetti(q, "y", n_ids = 3, seed = 7, return = "table")
  expect_identical(.Random.seed, old)
  expect_equal(length(unique(a$individuals$.id)), 3)
  expect_identical(a, panel_spaghetti(q, "y", n_ids = 3, seed = 7, return = "table"))
  rm(".Random.seed", envir = globalenv())
  on.exit(assign(".Random.seed", old, envir = globalenv()))
  expect_identical(a, panel_spaghetti(q, "y", n_ids = 3, seed = 7, return = "table"))
  expect_false(exists(".Random.seed", globalenv(), inherits = FALSE))
  expect_error(panel_spaghetti(q, "y", n_ids = 3, seed = NA_integer_), "seed")
  expect_false(exists(".Random.seed", globalenv(), inherits = FALSE))
})

test_that("chart dispatch builds actual layers and exposes transformed tables", {
  kinds <- c("line", "heatmap", "spaghetti", "tracking", "band", "bar", "stacked", "distribution")
  for (kind in kinds) {
    args <- list(x = p, var = if (kind == "stacked") c("a", "b") else "a", kind = kind)
    if (kind != "tracking") args$by <- "g"
    chart <- do.call(panel_plot, args)
    expect_s3_class(ggplot2::ggplot_build(chart), "ggplot_built")
    tab <- do.call(panel_plot, c(args, list(return = "table")))
    expect_true(is.data.frame(tab) || (kind == "spaghetti" && is.list(tab)))
  }
  expect_s3_class(ggplot2::ggplot_build(panel_line(p, "a", by = "g", facet = TRUE)), "ggplot_built")
  expect_message(panel_line(p, "a", by = "g", max_groups = 1), "largest")
  expect_message(panel_heatmap(p, "a", max_rows = 2), "Showing")
  expect_s3_class(ggplot2::ggplot_build(panel_heatmap(p, "a", diverge = TRUE)), "ggplot_built")
  long <- as_panel(data.frame(id = 1, t = seq(as.Date("2020-01-01"), by = "month", length.out = 36),
                               y = 1:36), id, t)
  expect_s3_class(ggplot2::ggplot_build(panel_heatmap(long, "y")), "ggplot_built")
})
