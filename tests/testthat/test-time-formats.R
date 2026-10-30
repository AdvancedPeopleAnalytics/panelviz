mk <- function(time) data.frame(who = rep(c("a", "b"), each = length(time)), t = rep(time, 2), y = seq_len(2 * length(time)))
kind_of <- function(time, ...) panel_meta(as_panel(mk(time), who, t, ...))

test_that("recognises many time encodings", {
  expect_equal(kind_of(2001:2005)$kind, "year")
  expect_equal(kind_of(c("1998 Q1", "1998 Q2", "1998 Q3"))$freq, "quarter")
  expect_equal(kind_of(c("2020-01", "2020-02", "2020-03"))$freq, "month")
  expect_equal(kind_of(c("2020-W01", "2020-W02", "2020-W03"))$freq, "week")
  expect_equal(kind_of(c(202001, 202002, 202003))$freq, "month")
  expect_equal(kind_of(c(20200101, 20200102, 20200103))$freq, "day")
  expect_equal(kind_of(c("Jan 2020", "Feb 2020", "Mar 2020"))$freq, "month")
  expect_equal(kind_of(c(1, 2, 3, 10))$kind, "index")
  expect_equal(kind_of(as.Date("2020-01-05") + c(0, 7, 14, 21))$freq, "week")
  expect_equal(kind_of(as.POSIXct("2020-01-01", tz = "UTC") + 86400 * 0:3)$freq, "day")
})

test_that("text dates: day>12 resolves m/d/Y, true ambiguity errors", {
  m <- kind_of(c("12/15/2019", "12/22/2019", "12/29/2019"))
  expect_equal(m$range[1], as.Date("2019-12-15"))
  expect_error(kind_of(c("01/02/2020", "03/04/2020")), "ambiguous")
  expect_equal(kind_of(c("01/02/2020", "03/04/2020"), time_format = "%d/%m/%Y")$range[1], as.Date("2020-02-01"))
})

test_that("two-digit years are expanded", {
  expect_message(m <- kind_of(c(68, 69, 70)), "two-digit")
  expect_equal(m$range[1], as.Date("1968-01-01"))
})

test_that("stata %tm/%tq values are read via the format attribute", {
  x <- structure(c(0, 1, 2), format.stata = "%tm")
  m <- panel_meta(as_panel(data.frame(who = 1, y = 1:3, t = I(1:3)) |> transform(t = x), who, t))
  expect_equal(m$kind, "month"); expect_equal(m$range[1], as.Date("1960-01-01"))
  q <- structure(c(0, 1), format.stata = "%tq")
  expect_equal(panel_meta(as_panel(data.frame(who = 1, y = 1:2, t = q), who, t))$freq, "quarter")
})

test_that("duplicate id-time rows are caught, composite ids fix them", {
  d <- data.frame(r = c("n", "n", "s", "s"), p = c("a", "b", "a", "b"), t = c(1, 1, 1, 1), y = 1:4)
  expect_error(as_panel(d, r, t), "repeat")
  expect_equal(panel_meta(as_panel(d, c(r, p), t))$n_ids, 4)
})
