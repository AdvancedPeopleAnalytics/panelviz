panel_colours <- c("#1d627e", "#e3120b", "#34b1e2", "#f2a900", "#6a8f3a",
                   "#8e5ea2", "#b4d5dd", "#7a7a7a")

#' Clean theme for panel graphics
#' @param font_size Base size.
#' @param base_family Font family ("" = device default).
#' @export
theme_panel <- function(font_size = 12, base_family = "") {
  grey <- "grey35"
  ggplot2::theme_minimal(base_size = font_size, base_family = base_family) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = grey),
      plot.title = ggplot2::element_text(face = "bold", size = font_size + 4),
      plot.subtitle = ggplot2::element_text(size = font_size),
      plot.caption = ggplot2::element_text(size = font_size - 3, colour = "grey50", hjust = 0),
      plot.title.position = "plot", plot.caption.position = "plot",
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(colour = "grey88", linewidth = 0.4),
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(size = font_size - 2),
      axis.ticks = ggplot2::element_blank(),
      legend.position = "bottom", legend.title = ggplot2::element_text(size = font_size - 2),
      legend.text = ggplot2::element_text(size = font_size - 2),
      strip.text = ggplot2::element_text(face = "bold", hjust = 0),
      plot.margin = ggplot2::margin(10, 14, 8, 10))
}
