# House style, modelled on the look of The Economist's charts: a red tag at the
# top left, a bold headline over a plain subtitle, a tinted plot area with white
# gridlines, value axis on the right, squares for legend keys at the top right,
# and an optional numbered square for figure references.

econ <- c(cyan = "#00a0dc", navy = "#00405c", steel = "#6b8ea4", salmon = "#ee8c6e",
          red = "#e3120b", amber = "#f1b434", green = "#6f9a3a", purple = "#8e5ea2")
panel_colours <- unname(econ[c("navy", "cyan", "salmon", "steel", "amber", "green", "purple", "red")])
bg_colour <- "#d6e4ec"
ink <- "#1a1a1a"

#' Best available condensed font
#'
#' Looks for Econ Sans Condensed, Avenir Next Condensed, Arial Narrow and a few
#' other narrow faces, then falls back to the device default. Override with
#' `options(tidyPanel.font = "My Font")`.
#' @return A font family name.
#' @export
panel_font <- function() {
  f <- getOption("tidyPanel.font")
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
#' @param style `"economist"` (default; also `options(tidyPanel.style = )`) or `"clean"`.
#' @export
theme_panel <- function(font_size = 12, base_family = panel_font(),
                        style = getOption("tidyPanel.style", "economist")) {
  style <- match.arg(style, c("economist", "clean"))
  if (style == "clean") return(theme_panel_clean(font_size, base_family))
  el <- ggplot2::element_text
  ggplot2::theme_minimal(base_size = font_size + 1, base_family = base_family) +
    ggplot2::theme(
      text = el(colour = ink),
      plot.background = ggplot2::element_rect(fill = bg_colour, colour = NA),
      panel.background = ggplot2::element_blank(),
      plot.title = el(face = "bold", size = font_size + 5, hjust = 0, lineheight = 0.95, margin = ggplot2::margin(b = 3)),
      plot.subtitle = el(size = font_size + 1, hjust = 0, margin = ggplot2::margin(b = 8)),
      plot.caption = el(size = font_size - 2, colour = "grey30", hjust = 0, margin = ggplot2::margin(t = 8)),
      plot.title.position = "plot", plot.caption.position = "plot",
      panel.grid.major.y = ggplot2::element_line(colour = "white", linewidth = 0.7),
      panel.grid.major.x = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.text = el(size = font_size, colour = ink),
      axis.line.x = ggplot2::element_line(colour = ink, linewidth = 0.5),
      axis.ticks.x = ggplot2::element_line(colour = ink, linewidth = 0.4),
      axis.ticks.length.x = grid::unit(4, "pt"),
      axis.ticks.y = ggplot2::element_blank(),
      legend.position = "top", legend.justification = "right", legend.direction = "horizontal",
      legend.title = ggplot2::element_blank(), legend.text = el(size = font_size),
      legend.key = ggplot2::element_blank(), legend.key.size = grid::unit(0.42, "cm"),
      legend.margin = ggplot2::margin(0, 0, 2, 0), legend.box.margin = ggplot2::margin(0, 0, 0, 0),
      strip.text = el(face = "bold", hjust = 0),
      plot.margin = ggplot2::margin(24, 14, 8, 12))
}

theme_panel_clean <- function(font_size = 12, base_family = "") {
  ggplot2::theme_minimal(base_size = font_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = "grey35"),
      plot.title = ggplot2::element_text(face = "bold", size = font_size + 4),
      plot.caption = ggplot2::element_text(size = font_size - 3, colour = "grey50", hjust = 0),
      plot.title.position = "plot", plot.caption.position = "plot",
      panel.grid.major.x = ggplot2::element_blank(), panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "grey88", linewidth = 0.4),
      axis.title = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
      legend.position = "bottom", legend.title = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0),
      plot.margin = ggplot2::margin(10, 14, 8, 10))
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
  plot$panel_style <- getOption("tidyPanel.style", "economist")
  plot
}

draw_deco <- function(x) {
  if (!identical(x$panel_style, "economist")) return(invisible())
  grid::grid.rect(x = grid::unit(0, "npc"), y = grid::unit(1, "npc"), width = grid::unit(1.1, "cm"),
                  height = grid::unit(0.2, "cm"), just = c("left", "top"),
                  gp = grid::gpar(fill = econ[["red"]], col = NA))
  if (!is.null(x$panel_tag)) {
    side <- grid::unit(0.72, "cm")
    grid::grid.rect(x = grid::unit(1, "npc") - grid::unit(10, "pt"), y = grid::unit(1, "npc") - grid::unit(12, "pt"),
                    width = side, height = side, just = c("right", "top"),
                    gp = grid::gpar(fill = econ[["steel"]], col = NA))
    grid::grid.text(as.character(x$panel_tag),
                    x = grid::unit(1, "npc") - grid::unit(10, "pt") - side * 0.5,
                    y = grid::unit(1, "npc") - grid::unit(12, "pt") - side * 0.5,
                    gp = grid::gpar(col = "white", fontface = "bold", fontsize = 15, fontfamily = panel_font()))
  }
  invisible()
}

#' @exportS3Method grid::grid.draw panel_plot
grid.draw.panel_plot <- function(x, recording = TRUE) {
  grid::grid.draw(ggplot2::ggplotGrob(x))
  draw_deco(x)
  invisible(x)
}

#' @export
print.panel_plot <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}
