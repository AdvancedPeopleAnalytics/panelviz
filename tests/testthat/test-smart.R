test_that("numbers switch units automatically with one precision per axis", {
  lab <- axis_labeller("x", c(10, 5e6))
  expect_equal(lab(c(0, 1e3, 1e6, 3e6)), c("0", "1K", "1M", "3M"))
  expect_equal(lab(c(500, 1500, 2500))[2], "1.5K")
  expect_equal(fmt_num(c(950, 1200, 3.4e6)), c("950", "1.2K", "3.4M"))
  expect_equal(fmt_num(-2500), "−2.5K")
})

test_that("percentages are detected from name and range, or from share", {
  expect_true(is_percent_var("churn_rate", c(0.1, 0.4)))
  expect_false(is_percent_var("income", c(0.1, 0.4)))
  expect_false(is_percent_var("churn_rate", c(10, 40)))
  expect_true(is_percent_var("x", c(5, 50), "share"))
  expect_equal(axis_labeller("churn_rate", c(0.1, 0.4))(0.25), "25%")
})

test_that("date labels show the year only where it changes", {
  d <- as.Date(c("2020-11-01", "2020-12-01", "2021-01-01", "2021-02-01"))
  expect_equal(period_labels("month")(d), c("Nov\n2020", "Dec", "Jan\n2021", "Feb"))
  expect_equal(period_labels("year")(d[1]), "2020")
  expect_equal(period_labels("quarter")(as.Date(c("2020-10-01", "2021-01-01"))), c("Q4\n2020", "Q1\n2021"))
})

d <- data.frame(who = rep(1:6, each = 5), yr = rep(2001:2005, 6),
                g = rep(c("x", "y"), each = 15), a = rep(c(1, 1, 1, 1, 2), 6) * rep(1:6, each = 5) * 1000)
d$a[d$g == "y"] <- d$a[d$g == "y"] * rep(c(1, 1.5, 2, 3, 4), 3)
p <- as_panel(d, who, yr)

test_that("headlines describe what happened", {
  one <- panel_line(p, "a")$labels$title
  expect_match(one, "^A (rose|more than doubled|grew)")
  expect_match(one, "between 2001 and 2005")
  expect_match(panel_bar(p, "a", by = "g")$labels$title, "leads on a at .*trails at")
  expect_match(panel_line(p, "a", by = "g", period = "all")$labels$subtitle, "Average a by g")
})

test_that("overtaking is called out and numeric groups are named", {
  e <- data.frame(who = rep(1:4, each = 4), t = rep(1:4, 4), g = rep(c(1, 2), each = 8),
                  v = c(10, 10, 10, 10, 10, 10, 10, 10, 5, 8, 12, 20, 5, 8, 12, 20))
  expect_match(panel_line(as_panel(e, who, t), "v", by = "g")$labels$title, "^G 2 overtook g 1")
})

test_that("column labels are used and titles can be switched to plain", {
  x <- d; attr(x$a, "label") <- "annual income (USD)"
  px <- as_panel(x, who, yr)
  expect_match(panel_line(px, "a")$labels$title, "^Annual income \\(USD\\)")
  op <- options(panelviz.smart_titles = FALSE); on.exit(options(op))
  expect_equal(panel_line(px, "a")$labels$title, "Annual income (USD)")
  expect_equal(panel_line(p, "a", title = "Mine")$labels$title, "Mine")
})

test_that("hidden thin groups are disclosed in the caption", {
  expect_match(panel_line(p, "a", by = "g", min_n = 2)$labels$caption, "under 2 individuals hidden")
})
