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

test_that("figure layouts reject invalid dimensions", {
  chart <- panel_line(p, "a")
  expect_error(panel_figure(list()), "at least one chart")
  for (n in list(0, -1, 1.5, NA_real_, Inf, c(1, 2), "two"))
    expect_error(panel_figure(chart, ncol = n), "positive whole number")
  expect_error(panel_figure(chart, heights = c(1, 2)), "heights")
  expect_error(panel_figure(chart, widths = c(1, 0)), "widths")
  expect_error(panel_figure(chart, widths = c(1, Inf)), "widths")
})

test_that("figures and plots print and save with device font fallback", {
  old <- options(panelviz.font = "panelviz missing test font")
  on.exit(options(old))
  chart <- panel_bar(p, "a", by = "g", tag = 1)
  family <- chart$layers[[2]]$aes_params$family
  f <- tempfile(fileext = ".pdf")
  save_panel(chart, f)
  expect_gt(file.size(f), 0)
  expect_identical(chart$layers[[2]]$aes_params$family, family)
  fig <- panel_figure(list(chart, panel_line(p, "a", style = "ft")), title = "Figure", style = "ft")
  save_panel(fig, f)
  expect_gt(file.size(f), 0)
  grDevices::pdf(f)
  tryCatch({
    expect_invisible(print(chart))
    expect_invisible(print(fig))
  }, finally = grDevices::dev.off())
  unlink(f)
  expect_error(save_panel(chart, tempfile(fileext = ".jpg")), "\\.png")
})

test_that("figure headlines wrap to the actual column width", {
  old <- options(panelviz.font = "")
  on.exit(options(old))
  out <- tempfile(fileext = ".pdf")
  grDevices::pdf(out, width = 6, height = 5)
  on.exit({ grDevices::dev.off(); unlink(out) }, add = TRUE)
  chart <- panel_line(p, "a",
                       title = "A deliberately long headline that must fit inside a narrow figure column",
                       subtitle = "A longer explanation of the comparison between individual trajectories and group averages")
  grid::pushViewport(grid::viewport(width = grid::unit(3, "in")))
  grob <- figure_plot_grob(chart)
  for (name in c("title", "subtitle")) {
    text <- grob$grobs[[match(name, grob$layout$name)]]$children[[1]]
    expect_match(text$label, "\n")
    for (line in strsplit(text$label, "\n", fixed = TRUE)[[1]]) {
      width <- grid::convertWidth(grid::grobWidth(grid::textGrob(line, gp = text$gp)), "in", valueOnly = TRUE)
      available <- grid::convertWidth(grid::unit(1, "npc") - grid::unit(24, "pt"), "in", valueOnly = TRUE)
      expect_lte(width, available)
    }
  }
  grid::popViewport()
  fig <- panel_figure(list(chart, chart))
  expect_invisible(print(fig))
})

test_that("cell direct labels stay inside the panel", {
  old <- options(panelviz.font = "")
  on.exit(options(old))
  lg <- data.frame(who = rep(1:6, each = 5), yr = rep(2001:2005, 6),
                   g = rep(c("Development", "Marketing"), each = 15),
                   a = rep(1:6, each = 5) * 1.5)
  chart <- panel_line(as_panel(lg, who, yr, source = "Unit test data"), "a", by = "g")
  x_sc <- Filter(function(s) "x" %in% s$aesthetics && inherits(s, "ScaleContinuous"),
                 chart$scales$scales)[[1]]
  before <- x_sc$expand
  out <- tempfile(fileext = ".pdf")
  grDevices::pdf(out, width = 6, height = 5)
  on.exit({ grDevices::dev.off(); unlink(out) }, add = TRUE)
  grid::pushViewport(grid::viewport(width = grid::unit(3, "in")))
  grob <- figure_plot_grob(chart)
  cell <- grid::convertWidth(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  P <- panel_width_in(grob, cell)
  edge <- panel_label_edge(grob, P)
  grid::popViewport()
  expect_true(is.finite(P) && is.finite(edge))
  expect_lte(edge, P)                    # the words are back inside the plot
  expect_identical(x_sc$expand, before)  # and the chart is left as we found it
})

test_that("font fallback does not hide unrelated rendering problems", {
  old <- options(panelviz.font = "")
  on.exit(options(old))
  expect_warning(with_font_fallback(function() warning("Visible rendering warning"),
                                    function() stop("Unexpected fallback")), "Visible rendering warning")
  expect_error(with_font_fallback(function() stop("Invalid chart data"),
                                  function() stop("Unexpected fallback")), "Invalid chart data")
  called <- FALSE
  expect_invisible(with_font_fallback(function() stop("invalid font"),
                                      function() { called <<- TRUE }))
  expect_true(called)
})
