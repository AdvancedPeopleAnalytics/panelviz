d <- data.frame(who = rep(1:4, each = 4), yr = rep(2001:2004, 4),
                grp = rep(c("x", "y"), each = 8), y = 1:16)
p <- as_panel(d, who, yr)

test_that("group mean per period", {
  a <- panel_aggregate(p, "y", by = "grp")
  expect_equal(a$y[a$grp == "x" & a$.period == as.Date("2001-01-01")], mean(c(1, 5)))
  expect_equal(unique(a$.n), 2)
})

test_that("two stages: sum within person then mean across people", {
  d2 <- data.frame(who = rep(1:2, each = 4), m = rep(paste0("2020-", c("01", "02", "03", "04")), 2), y = c(1, 2, 3, 4, 10, 20, 30, 40))
  q <- as_panel(d2, who, m)
  a <- panel_aggregate(q, "y", period = "quarter", fun_time = "sum", fun_group = "mean")
  expect_equal(a$y[1], mean(c(6, 60)))      # Q1 = Jan..Mar
  expect_equal(a$y[2], mean(c(4, 40)))      # Q2 = Apr
  expect_error(panel_aggregate(as_panel(d, who, yr), "y", period = "month"), "finer")
})

test_that("min_n drops thin groups; .id keeps individuals", {
  expect_equal(nrow(panel_aggregate(p, "y", by = "grp", min_n = 3)), 0)
  expect_equal(length(unique(panel_aggregate(p, "y", by = ".id")$.id)), 4)
})

test_that("summaries by name and function", {
  a <- panel_aggregate(p, "y", fun_group = "p90"); b <- panel_aggregate(p, "y", fun_group = function(v) max(v))
  expect_true(all(a$y <= b$y))
})

test_that("plots build for every chart", {
  for (f in list(panel_line, panel_heatmap, panel_spaghetti))
    expect_s3_class(f(p, "y", by = "grp"), "ggplot")
  expect_s3_class(panel_line(p, "y"), "ggplot")
  expect_s3_class(ggplot2::ggplot_build(panel_line(p, "y", by = "grp"))$plot, "ggplot")
})

test_that("all-time aggregation also supports plain time indices", {
  q <- as_panel(data.frame(id = rep(c("a", "b"), each = 3),
                            t = rep(1:3, 2), g = "all", y = c(1, 2, 3, 10, 20, 30)), id, t)
  a <- panel_aggregate(q, "y", period = "all", fun_time = "sum")
  expect_equal(a$y, 33)
  expect_equal(a$.n, 2)
  expect_equal(panel_bar(q, "y", by = "g", return = "table")$y, 11)
  expect_equal(nrow(panel_distribution(q, "y", return = "table")), 2)
  expect_error(panel_aggregate(q, "y", period = "month"), "plain index")
})

test_that("summaries handle missing data and preserve chronological first and last", {
  q <- as_panel(data.frame(id = 1, t = c(3, 1, 2, 4), y = c(6, NA, 2, 0)), id, t)
  expected <- list(mean = 8 / 3, median = 2, sum = 8, sd = stats::sd(c(2, 6, 0)),
                   min = 0, max = 6, first = 2, last = 0, n = 3, share = 2 / 3,
                   p0 = 0, p100 = 6)
  for (f in names(expected))
    expect_equal(panel_aggregate(q, "y", period = "all", fun_time = f)$y, expected[[f]])
  q$y <- NA_real_
  for (f in setdiff(names(expected), "n"))
    expect_true(is.na(panel_aggregate(q, "y", period = "all", fun_time = f)$y))
  expect_equal(panel_aggregate(q, "y", period = "all", fun_time = "n")$y, 0)
})

test_that("invalid aggregation requests fail explicitly", {
  expect_error(panel_aggregate(p, "absent"), "Unknown column")
  expect_error(panel_aggregate(p, "grp"), "Not numeric")
  expect_error(panel_aggregate(p, character()), "No numeric")
  expect_error(panel_aggregate(p, "y", fun_group = 1), "function or a name")
  expect_error(panel_aggregate(p, "y", fun_group = "unknown"), "Unknown summary")
  expect_error(panel_aggregate(p, "y", period = "fortnight"), "must be one of")
})
