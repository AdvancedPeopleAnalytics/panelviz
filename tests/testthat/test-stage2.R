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
