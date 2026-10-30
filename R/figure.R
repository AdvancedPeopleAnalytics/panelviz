#' Compose several charts into one numbered figure
#'
#' Lays charts out in a grid under one headline, numbers each panel in a square
#' at its top right, and adds a shared source and notes footer, like a page of
#' small multiples in a magazine.
#'
#' @param plots A list of charts from the `panel_*` functions.
#' @param ncol Number of columns.
#' @param title,subtitle Figure headline and optional line under it.
#' @param source Shared source line for the footer.
#' @param notes Optional footnotes (character vector, one per line).
#' @param tags Number the panels 1, 2, 3, ... (a chart's own `tag` wins).
#' @param heights,widths Relative sizes of rows and columns.
#' @param style Look for the figure frame; default is the first chart's style.
#' @return A `panel_figure`. Print it, or save it with [save_panel()].
#' @examples
#' \donttest{
#' d <- data.frame(who = rep(1:20, each = 6), yr = rep(2001:2006, 20),
#'                 grp = rep(c("a", "b"), each = 60), y = rnorm(120), z = runif(120))
#' p <- as_panel(d, who, yr, source = "simulated")
#' panel_figure(list(panel_line(p, "y", by = "grp"), panel_bar(p, "z", by = "grp")),
#'              title = "Two views of one panel")
#' }
#' @export
panel_figure <- function(plots, ncol = 2, title = NULL, subtitle = NULL, source = NULL, notes = NULL,
                         tags = TRUE, heights = NULL, widths = NULL, style = NULL) {
  if (!is.list(plots) || inherits(plots, "gg")) plots <- list(plots)
  ok <- vapply(plots, inherits, logical(1), "panel_plot")
  if (!all(ok)) cli::cli_abort("Every element of {.arg plots} must be a chart from a {.fn panel_*} function.")
  n <- length(plots); nrow <- ceiling(n / ncol)
  structure(list(plots = plots, ncol = ncol, nrow = nrow, title = title, subtitle = subtitle,
                 source = source, notes = notes, tags = tags,
                 heights = heights %||% rep(1, nrow), widths = widths %||% rep(1, ncol),
                 style = style %||% plots[[1]]$panel_style %||% "economist"),
            class = "panel_figure")
}

figure_lines <- function(f) c(if (!is.null(f$source)) paste0("Source: ", f$source), f$notes)

#' @exportS3Method grid::grid.draw panel_figure
grid.draw.panel_figure <- function(x, recording = TRUE) {
  with_font_fallback(function() draw_figure(x, FALSE),
                     function() draw_figure(x, TRUE))
  invisible(x)
}

draw_figure <- function(x, strip) {
  restores <- list()
  on.exit(for (r in restores) r())
  k <- style_spec(x$style)
  head_cm <- if (is.null(x$title)) 0.6 else if (is.null(x$subtitle)) 1.7 else 2.4
  foot_lines <- figure_lines(x)
  foot_cm <- if (length(foot_lines)) 0.35 + 0.42 * length(foot_lines) else 0.2
  lay <- grid::grid.layout(
    nrow = x$nrow + 2, ncol = x$ncol,
    heights = grid::unit.c(grid::unit(head_cm, "cm"), grid::unit(x$heights, "null"), grid::unit(foot_cm, "cm")),
    widths = grid::unit(x$widths, "null"))
  grid::grid.rect(gp = grid::gpar(fill = k$bg, col = NA))
  fam <- panel_font()
  if (identical(k$deco, "tag"))
    grid::grid.rect(x = 0, y = 1, width = grid::unit(1.1, "cm"), height = grid::unit(0.2, "cm"),
                    just = c("left", "top"), gp = grid::gpar(fill = k$decofill, col = NA))
  if (identical(k$deco, "rule"))
    grid::grid.rect(x = 0, y = 1, width = 1, height = grid::unit(0.07, "cm"), just = c("left", "top"),
                    gp = grid::gpar(fill = k$decofill, col = NA))
  if (!is.null(x$title))
    grid::grid.text(x$title, x = grid::unit(12, "pt"), y = grid::unit(1, "npc") - grid::unit(0.6, "cm"),
                    just = c("left", "top"), gp = grid::gpar(col = k$ink, fontface = "bold", fontsize = 19, fontfamily = fam))
  if (!is.null(x$subtitle))
    grid::grid.text(x$subtitle, x = grid::unit(12, "pt"), y = grid::unit(1, "npc") - grid::unit(1.45, "cm"),
                    just = c("left", "top"), gp = grid::gpar(col = k$ink, fontsize = 13, fontfamily = fam))
  if (length(foot_lines))
    grid::grid.text(paste(foot_lines, collapse = "\n"), x = grid::unit(12, "pt"), y = grid::unit(0.18, "cm"),
                    just = c("left", "bottom"), gp = grid::gpar(col = k$muted, fontsize = 10, lineheight = 1.1, fontfamily = fam))

  grid::pushViewport(grid::viewport(layout = lay))
  for (i in seq_along(x$plots)) {
    p <- x$plots[[i]]
    p$labels$caption <- NULL
    if (strip) { restores[[length(restores) + 1]] <- blank_layer_fonts(p); p <- strip_font(p) }
    p <- p + ggplot2::theme(plot.margin = ggplot2::margin(10, 12, 2, 12))
    if (is.null(p$panel_tag) && isTRUE(x$tags)) p$panel_tag <- i
    grid::pushViewport(grid::viewport(layout.pos.row = (i - 1) %/% x$ncol + 2, layout.pos.col = (i - 1) %% x$ncol + 1))
    grid::grid.draw(ggplot2::ggplotGrob(p))
    draw_deco(p, corner = FALSE)
    grid::popViewport()
  }
  grid::popViewport()
  invisible(x)
}

#' @export
print.panel_figure <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}

#' Save a chart or figure
#'
#' Works for any `panel_*` chart and for [panel_figure()]. Uses `ragg` when
#' installed for the best font rendering.
#'
#' @param x A chart or figure.
#' @param file Path ending in `.png`, `.pdf` or `.svg`.
#' @param width,height Size in inches.
#' @param dpi Resolution for PNG.
#' @return `file`, invisibly.
#' @export
save_panel <- function(x, file, width = 9, height = 5, dpi = 150) {
  ext <- tolower(tools::file_ext(file))
  switch(ext,
    png = if (requireNamespace("ragg", quietly = TRUE)) ragg::agg_png(file, width = width, height = height, units = "in", res = dpi)
          else grDevices::png(file, width = width, height = height, units = "in", res = dpi),
    pdf = grDevices::pdf(file, width = width, height = height),
    svg = grDevices::svg(file, width = width, height = height),
    cli::cli_abort("Use a .png, .pdf or .svg file name."))
  on.exit(grDevices::dev.off())
  grid::grid.newpage()
  grid::grid.draw(x)
  invisible(file)
}
