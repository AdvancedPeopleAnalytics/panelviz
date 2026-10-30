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
  if (length(plots) == 0) cli::cli_abort("{.arg plots} must contain at least one chart.")
  if (!all(ok)) cli::cli_abort("Every element of {.arg plots} must be a chart from a {.fn panel_*} function.")
  if (!is.numeric(ncol) || length(ncol) != 1 || is.na(ncol) ||
      !is.finite(ncol) || ncol < 1 || ncol != floor(ncol))
    cli::cli_abort("{.arg ncol} must be a positive whole number.")
  n <- length(plots); nrow <- ceiling(n / ncol)
  check_sizes <- function(sizes, n, arg) {
    if (!is.null(sizes) && (!is.numeric(sizes) || length(sizes) != n ||
        anyNA(sizes) || any(!is.finite(sizes) | sizes <= 0)))
      cli::cli_abort("{.arg {arg}} must contain {n} positive finite value{?s}.")
  }
  check_sizes(heights, nrow, "heights")
  check_sizes(widths, ncol, "widths")
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
  fam <- panel_font()
  title_width_in <- max(1.5, device_width_in() - 0.5)
  title_gp <- grid::gpar(col = k$ink, fontface = "bold", fontsize = 19, fontfamily = fam, lineheight = 0.95)
  sub_gp <- grid::gpar(col = k$ink, fontsize = 13, fontfamily = fam, lineheight = 1.0)
  fig_title <- wrap_to_width(x$title, title_gp, title_width_in)
  fig_subtitle <- wrap_to_width(x$subtitle, sub_gp, title_width_in)
  # The header band is measured off the text it holds, so a headline that runs to
  # two lines pushes the panels down instead of sitting on them.
  top_cm <- 0.5
  g_title <- if (is.null(fig_title)) NULL else
    grid::textGrob(fig_title, x = grid::unit(12, "pt"),
                   y = grid::unit(1, "npc") - grid::unit(top_cm, "cm"),
                   just = c("left", "top"), gp = title_gp)
  h_title <- if (is.null(g_title)) 0 else
    grid::convertHeight(grid::grobHeight(g_title), "cm", valueOnly = TRUE)
  sub_cm <- top_cm + h_title + if (h_title > 0) 0.25 else 0
  g_sub <- if (is.null(fig_subtitle)) NULL else
    grid::textGrob(fig_subtitle, x = grid::unit(12, "pt"),
                   y = grid::unit(1, "npc") - grid::unit(sub_cm, "cm"),
                   just = c("left", "top"), gp = sub_gp)
  h_sub <- if (is.null(g_sub)) 0 else
    grid::convertHeight(grid::grobHeight(g_sub), "cm", valueOnly = TRUE)
  head_cm <- max(0.6, sub_cm + h_sub + 0.15)
  foot_lines <- figure_lines(x)
  foot_cm <- if (length(foot_lines)) 0.35 + 0.42 * length(foot_lines) else 0.2
  lay <- grid::grid.layout(
    nrow = x$nrow + 2, ncol = x$ncol,
    heights = grid::unit.c(grid::unit(head_cm, "cm"), grid::unit(x$heights, "null"), grid::unit(foot_cm, "cm")),
    widths = grid::unit(x$widths, "null"))
  grid::grid.rect(gp = grid::gpar(fill = k$bg, col = NA))
  if (identical(k$deco, "tag"))
    grid::grid.rect(x = 0, y = 1, width = grid::unit(1.1, "cm"), height = grid::unit(0.2, "cm"),
                    just = c("left", "top"), gp = grid::gpar(fill = k$decofill, col = NA))
  if (identical(k$deco, "rule"))
    grid::grid.rect(x = 0, y = 1, width = 1, height = grid::unit(0.07, "cm"), just = c("left", "top"),
                    gp = grid::gpar(fill = k$decofill, col = NA))
  if (!is.null(g_title)) grid::grid.draw(g_title)
  if (!is.null(g_sub)) grid::grid.draw(g_sub)
  if (length(foot_lines))
    grid::grid.text(paste(foot_lines, collapse = "\n"), x = grid::unit(12, "pt"), y = grid::unit(0.18, "cm"),
                    just = c("left", "bottom"), gp = grid::gpar(col = k$muted, fontsize = 10, lineheight = 1.1, fontfamily = fam))

  grid::pushViewport(grid::viewport(layout = lay))
  for (i in seq_along(x$plots)) {
    p <- x$plots[[i]]
    p$labels$caption <- NULL
    if (strip) { restores[[length(restores) + 1]] <- blank_layer_fonts(p); p <- strip_font(p) }
    if (is.null(p$panel_tag) && isTRUE(x$tags)) p$panel_tag <- i
    p <- p + ggplot2::theme(plot.margin = ggplot2::margin(if (is.null(p$panel_tag)) 10 else 40, 12, 2, 12))
    grid::pushViewport(grid::viewport(layout.pos.row = (i - 1) %/% x$ncol + 2, layout.pos.col = (i - 1) %% x$ncol + 1))
    grid::grid.draw(figure_plot_grob(p))
    draw_deco(p, corner = FALSE)
    grid::popViewport()
  }
  grid::popViewport()
  invisible(x)
}

figure_plot_grob <- function(p) {
  p <- cell_theme(p)
  width <- grid::convertWidth(grid::unit(1, "npc") - grid::unit(24, "pt"), "in", valueOnly = TRUE)
  if (width <= 0) cli::cli_abort("Figure columns are too narrow; increase the figure width or reduce {.arg ncol}.")
  p <- fit_legend_to_width(p, width)
  g <- ggplot2::ggplotGrob(p)
  for (name in c("title", "subtitle")) {
    label <- p$labels[[name]]
    if (is.null(label) || !is.character(label)) next
    grob <- g$grobs[[match(name, g$layout$name)]]
    if (!length(grob$children)) next
    gp <- grob$children[[1]]$gp
    if (is.null(gp)) next
    p$labels[[name]] <- wrap_to_width(label, gp, width)
  }
  build_cell_grob(p, width)
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
