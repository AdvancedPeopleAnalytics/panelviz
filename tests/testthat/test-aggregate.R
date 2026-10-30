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
