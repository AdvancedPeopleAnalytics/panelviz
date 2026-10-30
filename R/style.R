# House style, modelled on the look of The Economist's charts: a red tag at the
# top left, a bold headline over a plain subtitle, a tinted plot area with white
# gridlines, value axis on the right, squares for legend keys at the top right,
# and an optional numbered square for figure references.

econ <- c(cyan = "#00a0dc", navy = "#00405c", steel = "#6b8ea4", salmon = "#ee8c6e",
          red = "#e3120b", amber = "#f1b434", green = "#6f9a3a", purple = "#8e5ea2")

# One entry per look. Everything a chart colours comes from here.
panel_style_specs <- list(
  economist = list(bg = "#d6e4ec", grid = "white", ink = "#1a1a1a", muted = "grey30", deco = "tag", decofill = econ[["red"]],
                   tagfill = econ[["steel"]], y_pos = "right",
                   palette = unname(econ[c("navy", "cyan", "salmon", "steel", "amber", "green", "purple", "red")]),
                   primary = econ[["cyan"]], accent = econ[["red"]], track = c("#00a0dc", "#00405c"),
                   stack = unname(econ[c("cyan", "navy", "steel", "salmon", "amber", "green")]),
                   seq = c("#eef5f9", "#b5dcee", "#00a0dc", "#00587a", "#00293d"), div = c("#00587a", "#e3120b")),
  ft = list(bg = "#fff1e5", grid = "#eadccf", ink = "#33302e", muted = "#66605c", deco = "rule", decofill = "#33302e",
            tagfill = "#0f5499", y_pos = "right",
            palette = c("#0f5499", "#990f3d", "#0d7680", "#ff8833", "#96cc28", "#262a33", "#ff7faa", "#cc0000"),
            primary = "#0f5499", accent = "#990f3d", track = c("#0f5499", "#990f3d"),
            stack = c("#0f5499", "#0d7680", "#ff8833", "#990f3d", "#96cc28", "#262a33"),
            seq = c("#fdf0e4", "#cde0f0", "#7fb0d8", "#2f6eb0", "#0f3b73"), div = c("#0f5499", "#990f3d")),
  clean = list(bg = "white", grid = "#e5e5e5", ink = "grey25", muted = "grey50", deco = "none", decofill = NA,
               tagfill = "#7a7a7a", y_pos = "left",
               palette = c("#1d627e", "#e3120b", "#34b1e2", "#f2a900", "#6a8f3a", "#8e5ea2", "#b4d5dd", "#7a7a7a"),
               primary = "#1d627e", accent = "#e3120b", track = c("#43bdd3", "#005265"),
               stack = c("#1d627e", "#34b1e2", "#b4d5dd", "#adc0cb", "#7a7a7a", "#f2a900"),
               seq = c("#f4f9fb", "#b4d5dd", "#34b1e2", "#1d627e", "#06303f"), div = c("#1d627e", "#e3120b")),
  dark = list(bg = "#16222c", grid = "#2b3b48", ink = "#e6edf2", muted = "#9fb0bd", deco = "tag", decofill = "#4cc9f0",
              tagfill = "#4cc9f0", y_pos = "right",
              palette = c("#4cc9f0", "#f72585", "#ffd166", "#80ed99", "#b794f6", "#ff9770", "#a0aec0", "#ffffff"),
              primary = "#4cc9f0", accent = "#f72585", track = c("#4cc9f0", "#f72585"),
              stack = c("#4cc9f0", "#f72585", "#ffd166", "#80ed99", "#b794f6", "#ff9770"),
              seq = c("#1d2f3d", "#1f5f7a", "#2a9fd6", "#8fd6f5", "#e8f7ff"), div = c("#4cc9f0", "#f72585")),
  mono = list(bg = "white", grid = "grey90", ink = "black", muted = "grey40", deco = "none", decofill = NA,
              tagfill = "grey30", y_pos = "left",
              palette = c("#000000", "#8c8c8c", "#bdbdbd", "#404040", "#d9d9d9", "#a6a6a6", "#595959", "#e6e6e6"),
              primary = "#404040", accent = "#000000", track = c("#8c8c8c", "#000000"),
              stack = c("#404040", "#8c8c8c", "#bdbdbd", "#d9d9d9", "#595959", "#a6a6a6"),
              seq = c("grey96", "grey82", "grey62", "grey35", "grey10"), div = c("grey35", "black"))
)

#' Available looks
#'
#' `"economist"` (default), `"ft"`, `"clean"`, `"dark"` and `"mono"` (print-friendly greys).
#' Choose one for a session with `use_panel_style()`, or per chart with `style =`.
#' @return `panel_styles()` returns the names.
#' @export
panel_styles <- function() names(panel_style_specs)

#' Set the look for the session
#'
#' @param style One of [panel_styles()].
#' @return The previous style, invisibly.
#' @export
use_panel_style <- function(style = "economist") {
  style <- match.arg(style, panel_styles())
  invisible(options(panelviz.style = style)[[1]])
}

style_spec <- function(style = getOption("panelviz.style", "economist")) {
  if (!style %in% names(panel_style_specs))
    cli::cli_abort("Unknown style {.val {style}}; choose from {.val {panel_styles()}}.")
  panel_style_specs[[style]]
}

#' Best available condensed font
#'
#' Looks for Econ Sans Condensed, Avenir Next Condensed, Arial Narrow and a few
#' other narrow faces, then falls back to the device default. Override with
#' `options(panelviz.font = "My Font")`.
#' @return A font family name.
#' @export
panel_font <- function() {
  f <- getOption("panelviz.font")
  if (!is.null(f)) return(f)
  if (!requireNamespace("systemfonts", quietly = TRUE)) return("")
  have <- unique(systemfonts::system_fonts()$family)
  for (cand in c("Econ Sans Condensed", "Avenir Next Condensed", "Arial Narrow", "PT Sans Narrow",
                 "Helvetica Neue", "Segoe UI"))
    if (cand %in% have) return(cand)
  ""
}

#' Theme for panel graphics
#'
#' @param font_size Base size.
#' @param base_family Font family; defaults to [panel_font()].
#' @param style One of [panel_styles()]; default `"economist"` (or `options(panelviz.style = )`).
#' @export
theme_panel <- function(font_size = 12, base_family = panel_font(),
                        style = getOption("panelviz.style", "economist")) {
  k <- style_spec(style)
  el <- ggplot2::element_text
  ggplot2::theme_minimal(base_size = font_size + 1, base_family = base_family) +
    ggplot2::theme(
      text = el(colour = k$ink),
      plot.background = ggplot2::element_rect(fill = k$bg, colour = NA),
      panel.background = ggplot2::element_blank(),
      plot.title = el(face = "bold", size = font_size + 5, hjust = 0, lineheight = 0.95, margin = ggplot2::margin(b = 3)),
      plot.subtitle = el(size = font_size + 1, hjust = 0, margin = ggplot2::margin(b = 8)),
      plot.caption = el(size = font_size - 2, colour = k$muted, hjust = 0, lineheight = 1.05, margin = ggplot2::margin(t = 8)),
      plot.title.position = "plot", plot.caption.position = "plot",
      panel.grid.major.y = ggplot2::element_line(colour = k$grid, linewidth = 0.7),
      panel.grid.major.x = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text = el(size = font_size, colour = k$ink),
      axis.line.x = ggplot2::element_line(colour = k$ink, linewidth = 0.5),
      axis.ticks.x = ggplot2::element_line(colour = k$ink, linewidth = 0.4),
      axis.ticks.length.x = grid::unit(4, "pt"),
      axis.ticks.y = ggplot2::element_blank(),
      legend.position = "top", legend.justification = "right", legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(), legend.text = el(size = font_size),
      legend.key = ggplot2::element_blank(), legend.key.size = grid::unit(0.42, "cm"),
      legend.margin = ggplot2::margin(0, 0, 2, 0), legend.box.margin = ggplot2::margin(0, 0, 0, 0),
      strip.text = el(face = "bold", hjust = 0),
      plot.margin = ggplot2::margin(24, 14, 8, 12))
}

# ---- decorations -------------------------------------------------------------
# The red tag and the numbered square are drawn when the plot is printed or
# saved, so the object stays an ordinary ggplot that you can keep adding to.

panel_deco <- function(tag = NULL) structure(list(tag = tag), class = "panel_deco")

#' The theme plus decorations, added at the end of every chart
#' @noRd
panel_style <- function(tag = NULL, ...) {
  list(theme_panel(...), panel_deco(tag))
}

#' @exportS3Method ggplot2::ggplot_add panel_deco
ggplot_add.panel_deco <- function(object, plot, object_name) {
  if (!inherits(plot, "panel_plot")) class(plot) <- c("panel_plot", class(plot))
  plot$panel_tag <- object$tag
  plot$panel_style <- getOption("panelviz.style", "economist")
  plot
}

draw_deco <- function(x, corner = TRUE) {
  k <- style_spec(x$panel_style %||% "economist")
  if (corner && identical(k$deco, "tag"))
    grid::grid.rect(x = grid::unit(0, "npc"), y = grid::unit(1, "npc"), width = grid::unit(1.1, "cm"),
                    height = grid::unit(0.2, "cm"), just = c("left", "top"), gp = grid::gpar(fill = k$decofill, col = NA))
  if (corner && identical(k$deco, "rule"))
    grid::grid.rect(x = grid::unit(0, "npc"), y = grid::unit(1, "npc"), width = grid::unit(1, "npc"),
                    height = grid::unit(0.07, "cm"), just = c("left", "top"), gp = grid::gpar(fill = k$decofill, col = NA))
  if (!is.null(x$panel_tag)) {
    side <- grid::unit(0.72, "cm")
    grid::grid.rect(x = grid::unit(1, "npc") - grid::unit(10, "pt"), y = grid::unit(1, "npc") - grid::unit(12, "pt"),
                    width = side, height = side, just = c("right", "top"),
                    gp = grid::gpar(fill = k$tagfill, col = NA))
    grid::grid.text(as.character(x$panel_tag),
                    x = grid::unit(1, "npc") - grid::unit(10, "pt") - side * 0.5,
                    y = grid::unit(1, "npc") - grid::unit(12, "pt") - side * 0.5,
                    gp = grid::gpar(col = if (identical(x$panel_style, "dark")) "#16222c" else "white",
                                    fontface = "bold", fontsize = 15, fontfamily = panel_font()))
  }
  invisible()
}

# Some devices (pdf, postscript) cannot use system fonts. Try the preferred font first;
# if the device refuses it, redraw on a fresh page with the device's default family.
strip_font <- function(p) p + ggplot2::theme(text = ggplot2::element_text(family = ""))

# Layers are ggproto objects that cannot be copied safely, so blank their font in place and
# hand back a function that restores it.
blank_layer_fonts <- function(p) {
  saved <- lapply(p$layers, function(l) l$aes_params$family)
  for (l in p$layers) if (!is.null(l$aes_params$family)) l$aes_params$family <- ""
  function() for (i in seq_along(p$layers)) if (!is.null(saved[[i]])) p$layers[[i]]$aes_params$family <- saved[[i]]
}

with_font_fallback <- function(draw, fallback) {
  device <- names(grDevices::dev.cur())
  fonts <- if (identical(device, "pdf")) names(grDevices::pdfFonts()) else
    if (identical(device, "postscript")) names(grDevices::postscriptFonts()) else NULL
  if (!is.null(fonts) && !panel_font() %in% c("", fonts)) {
    rlang::local_options(panelviz.font = "")
    fallback()
    return(invisible())
  }
  ok <- tryCatch({ draw(); TRUE },
                 error = function(e) if (grepl("invalid font|font family|font type", conditionMessage(e))) FALSE else stop(e))
  if (!ok) {
    grid::grid.newpage()
    rlang::local_options(panelviz.font = "")
    fallback()
  }
  invisible()
}

#' @exportS3Method grid::grid.draw panel_plot
grid.draw.panel_plot <- function(x, recording = TRUE) {
  with_font_fallback(
    function() { grid::grid.draw(ggplot2::ggplotGrob(x)); draw_deco(x) },
    function() {
      restore <- blank_layer_fonts(x); on.exit(restore())
      y <- strip_font(x); grid::grid.draw(ggplot2::ggplotGrob(y)); draw_deco(y)
    })
  invisible(x)
}

#' @export
print.panel_plot <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}
