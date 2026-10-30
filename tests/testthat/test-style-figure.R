d <- data.frame(who = rep(1:6, each = 5), yr = rep(2001:2005, 6), g = rep(c("x", "y"), each = 15),
                a = rep(1:6, each = 5) * 1.5, b = 2)
p <- as_panel(d, who, yr, source = "Unit test data")

test_that("source appears in the footer and can be overridden", {
  expect_match(panel_line(p, "a")$labels$caption, "^Source: Unit test data\n")
  expect_match(panel_line(p, "a", source = "Mine")$labels$caption, "^Source: Mine")
  expect_false(grepl("Source", panel_line(as_panel(d, who, yr), "a")$labels$caption))
  f <- tempfile(fileext = ".csv"); utils::write.csv(d, f, row.names = FALSE)
  expect_match(panel_line(read_panel(f, who, yr), "a")$labels$caption, "Source: file")
})

test_that("every style draws every chart", {
  for (st in panel_styles()) {
    for (fn in list(panel_line, panel_heatmap, panel_spaghetti, panel_tracking))
      expect_s3_class(fn(p, "a", style = st), "ggplot")
    expect_s3_class(panel_bar(p, "a", by = "g", style = st), "ggplot")
    expect_equal(panel_line(p, "a", style = st)$panel_style, st)
  }
  expect_error(panel_line(p, "a", style = "nope"), "Unknown style")
})

test_that("use_panel_style sets the session default and economist is the default", {
  expect_equal(panel_line(p, "a")$panel_style, "economist")
  old <- use_panel_style("ft"); on.exit(options(panelviz.style = NULL))
  expect_equal(panel_line(p, "a")$panel_style, "ft")
})

test_that("figures compose, number panels and save", {
  skip_if_not_installed("systemfonts")
  f <- panel_figure(list(panel_line(p, "a", by = "g"), panel_bar(p, "a", by = "g"), panel_tracking(p, "a")),
                    title = "T", subtitle = "S", source = "Src", notes = "Note")
  expect_s3_class(f, "panel_figure")
  expect_equal(f$nrow, 2)
  out <- tempfile(fileext = ".png")
  save_panel(f, out, width = 8, height = 6)
  expect_gt(file.size(out), 5000)
  save_panel(panel_line(p, "a", tag = 3), out)
  expect_error(panel_figure(list(ggplot2::ggplot())), "panel_")
})
