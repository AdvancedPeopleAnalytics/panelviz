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

# ---- text that has to fit ----------------------------------------------------
# Titles are computed as plain strings, so where the line breaks go depends on
# the device the chart lands on. Break them while drawing, measured against the
# space that is actually there, rather than guessing a number of characters.

device_width_in <- function() {
  w <- tryCatch(grid::convertWidth(grid::unit(1, "npc"), "in", valueOnly = TRUE),
                error = function(e) NA_real_)
  if (!is.finite(w) || w <= 0) 8 else w
}

text_width_in <- function(txt, gp) {
  grid::convertWidth(grid::grobWidth(grid::textGrob(txt, gp = gp)), "in", valueOnly = TRUE)
}

#' Break text so that no line measures wider than `width_in` inches
#'
#' A line that already fits is returned unchanged; `strwrap()` needs a width one
#' greater than the line to leave it alone, hence the first attempt at `nchar + 1`.
#' The next attempt shrinks towards the measured overshoot, so a headline a little
#' too wide breaks in one step instead of twenty.
#' @noRd
wrap_to_width <- function(txt, gp, width_in, min_width = 10) {
  if (is.null(txt) || !is.character(txt)) return(NULL)
  txt <- paste(txt, collapse = "\n")
  if (!nzchar(txt)) return(NULL)
  if (!is.finite(width_in) || width_in <= 0) return(txt)
  lines <- strsplit(txt, "\n", fixed = TRUE)[[1]]
  out <- vapply(lines, function(line) {
    if (!nzchar(line)) return("")
    w <- nchar(line) + 1L
    repeat {
      pieces <- strwrap(line, width = max(min_width, w))
      widths <- vapply(pieces, text_width_in, numeric(1), gp = gp)
      if (all(widths <= width_in)) return(paste(pieces, collapse = "\n"))
      over <- max(widths) / width_in
      w <- min(w - 1L, max(min_width - 1L, floor(w / max(over, 1.05)) - 1L))
      if (w < min_width) return(paste(strwrap(line, width = min_width), collapse = "\n"))
    }
  }, character(1), USE.NAMES = FALSE)
  paste(out, collapse = "\n")
}

#' Wrap a chart's headline, subtitle and footer to the width it is drawn at
#'
#' Reads the text properties off the built grob, so the break uses the font and
#' size the chart really draws with. The first grob is reused when nothing had
#' to break, which is the common case.
#' @noRd
labels_that_fit <- function(p, width_in = NULL) {
  if (is.null(width_in)) {
    inset <- 26                                     # default plot.margin, in points
    m <- tryCatch(p$theme$plot.margin, error = function(e) NULL)
    if (!is.null(m) && length(m) >= 4) {
      lr <- tryCatch(grid::convertWidth(m[[2]] + m[[4]], "in", valueOnly = TRUE),
                     error = function(e) NA_real_)
      if (is.finite(lr)) inset <- lr * 72
    }
    width_in <- device_width_in() - inset / 72
  }
  if (!is.finite(width_in) || width_in <= 0) return(list(plot = p, grob = NULL))
  g <- ggplot2::ggplotGrob(p)
  changed <- FALSE
  for (name in c("title", "subtitle", "caption")) {
    label <- p$labels[[name]]
    if (is.null(label) || !is.character(label)) next
    grob <- g$grobs[[match(name, g$layout$name)]]
    if (!length(grob$children)) next
    gp <- grob$children[[1]]$gp
    if (is.null(gp)) next
    broke <- wrap_to_width(label, gp, width_in)
    if (!identical(broke, label)) { p$labels[[name]] <- broke; changed <- TRUE }
  }
  list(plot = p, grob = if (changed) ggplot2::ggplotGrob(p) else g)
}

# Type inside a figure cell is smaller than on a full-size chart: a cell is about
# a quarter of the page, and the headline has to leave room for the plot itself.
cell_theme <- function(p) {
  p + ggplot2::theme(
    plot.title = ggplot2::element_text(size = 13, lineheight = 0.95, margin = ggplot2::margin(b = 3)),
    plot.subtitle = ggplot2::element_text(size = 10, lineheight = 1.05, margin = ggplot2::margin(b = 6)),
    axis.text = ggplot2::element_text(size = 9),
    legend.text = ggplot2::element_text(size = 9),
    legend.key.size = grid::unit(0.3, "cm"),
    legend.margin = ggplot2::margin(0, 0, 2, 0),
    axis.ticks.length.x = grid::unit(3, "pt"))
}

# Label text drawn by a layer (direct labels on a line, values on a bar) stays at
# full size on a whole page, where it is the same size as the axis text.
cell_label_scale <- 0.7

#' Widths and key counts of the legend boxes on a built chart
#' @noRd
guide_box_info <- function(g) {
  out <- list()
  for (i in grep("^guide-box", g$layout$name)) {
    box <- g$grobs[[i]]
    if (!inherits(box, "gtable")) next
    w <- suppressWarnings(grid::convertWidth(grid::grobWidth(box), "in", valueOnly = TRUE))
    if (!is.finite(w) || w <= 0) next
    inner <- if (length(box$grobs)) box$grobs[[1]] else NULL
    keys <- if (inherits(inner, "gtable")) sum(grepl("^key-", inner$layout$name)) else 0L
    out[[length(out) + 1]] <- list(width = w, keys = keys)
  }
  out
}

guide_ncol <- function(k) {
  g <- tryCatch(ggplot2::guide_legend(ncol = k, byrow = TRUE), error = function(e) NULL)
  if (is.null(g)) ggplot2::guide_legend(ncol = k) else g   # byrow keeps the reading order row-wise
}

#' Lay a legend out in as many rows as the cell needs
#'
#' A horizontal legend is always one row wide, so in a narrow cell it runs over
#' the neighbouring panel. Count the keys, work out the rows the width allows and
#' ask the guides for that many columns.
#' @noRd
fit_legend_to_width <- function(p, width_in) {
  scales <- Filter(function(s) inherits(s, "ScaleDiscrete"), p$scales$scales)
  if (!length(scales)) return(p)
  info <- guide_box_info(ggplot2::ggplotGrob(p))
  if (!length(info)) return(p)
  w <- max(vapply(info, `[[`, numeric(1), "width"))
  if (w <= width_in) return(p)
  keys <- max(vapply(info, `[[`, numeric(1), "keys"))
  if (keys < 2) return(p)
  aes <- unique(vapply(scales, function(s) s$aesthetics[[1]], character(1)))
  best <- p
  # Fewest rows first: columns are added only while the legend is still too wide.
  for (k in seq(max(1, ceiling(keys / ceiling(w / width_in))), 1)) {
    args <- stats::setNames(rep(list(guide_ncol(k)), length(aes)), aes)
    cand <- p + do.call(ggplot2::guides, args)
    boxes <- guide_box_info(ggplot2::ggplotGrob(cand))
    if (length(boxes) && max(vapply(boxes, `[[`, numeric(1), "width")) <= width_in) return(cand)
    best <- cand
  }
  best
}

#' Build a cell grob with the date axis thinned to the space it has
#'
#' Breaks are chosen for a full-width chart, where eight dates side by side are
#' comfortable; in a cell they collide. Measured against the labels' own width,
#' then put back, because the chart object belongs to the caller.
#' @noRd
build_cell_grob <- function(p, width_in) {
  restores <- list()
  on.exit(for (r in restores) r(), add = TRUE)
  gp <- grid::gpar(fontsize = 9, fontfamily = panel_font())
  for (s in p$scales$scales) {
    br <- s$breaks
    if (!inherits(br, c("Date", "POSIXt"))) next
    labs <- if (is.function(s$labels)) s$labels(br) else if (is.character(s$labels)) s$labels else format(br)
    widths <- vapply(labs, function(lab) {
      lines <- strsplit(as.character(lab), "\n", fixed = TRUE)[[1]]
      max(vapply(lines, text_width_in, numeric(1), gp = gp))
    }, numeric(1))
    label_in <- max(widths[is.finite(widths) & widths > 0], na.rm = TRUE)
    if (!is.finite(label_in)) next
    room <- max(1, width_in - 0.4)                  # the value axis takes a strip of the cell
    keep <- max(3L, floor((room + 0.08) / (label_in + 0.08)))
    if (length(br) <= keep) next
    step <- ceiling(length(br) / keep)
    restores[[length(restores) + 1]] <- local({ sc <- s; old <- br; function() sc$breaks <- old })
    s$breaks <- br[seq(1, length(br), by = step)]
  }
  for (l in p$layers) {
    if (!inherits(l$geom, c("GeomText", "GeomLabel"))) next
    sz <- l$aes_params$size
    if (!is.numeric(sz) || !length(sz) || !is.finite(sz[1])) next
    restores[[length(restores) + 1]] <- local({ lay <- l; old <- sz; function() lay$aes_params$size <- old })
    l$aes_params$size <- sz * cell_label_scale
  }
  g <- ggplot2::ggplotGrob(p)
  fit <- fit_direct_labels(p, g)
  if (!is.null(fit$restore)) restores[[length(restores) + 1]] <- fit$restore
  fit$grob
}

# ---- direct labels inside a cell --------------------------------------------
# End labels on a line chart sit in the right-hand expansion of the x scale.
# That expansion is sized for a whole page, so in a cell the words run past the
# panel edge and into the value axis. Measure where the labels end on the built
# grob, solve for the expansion that pulls them back inside, and rebuild once.

# How far inside the panel edge the labels are kept. The value axis text starts
# a little to the right of the edge, and the panel width is measured rather than
# exact, so the gap absorbs both.
label_gap_in <- 0.05
# The most room the right-hand expansion may take, as a fraction of the data
# range: past this the chart would be mostly padding.
label_expand_max <- 0.6

# Every text grob drawn inside a panel, however deeply it is nested.
panel_text_grobs <- function(grob) {
  out <- list()
  walk <- function(z) {
    if (inherits(z, "text")) { out[[length(out) + 1]] <<- z; return(invisible(NULL)) }
    if (inherits(z, "gTree") && length(z$children))
      for (k in z$children) if (!is.null(k)) walk(k)
  }
  if (!is.null(grob)) walk(grob)
  out
}

# The panel column's width in inches: the cell less every other gtable column,
# with those columns' flexing (null) parts taken out.
panel_width_in <- function(g, cell_w) {
  row <- which(g$layout$name == "panel")
  if (length(row) != 1) return(NA_real_)
  col <- g$layout$l[[row]]
  others <- 0
  for (i in seq_along(g$widths)) {
    if (i == col) next
    u <- g$widths[i]
    s <- as.character(u)
    m <- regmatches(s, gregexpr("[-0-9.]+null", s))[[1]]
    nw <- if (length(m) && nzchar(m[[1]])) sum(as.numeric(sub("null$", "", m))) else 0
    w <- tryCatch(grid::convertWidth(u - nw * grid::unit(1, "null"), "in", valueOnly = TRUE),
                  error = function(e) NA_real_)
    if (!is.finite(w)) return(NA_real_)
    others <- others + w
  }
  cell_w - others
}

# A unit vector of panel positions, in the [0, 1] space the panel is drawn in.
panel_position <- function(u) {
  s <- as.character(u)
  if (!length(s) || !all(grepl("^-?[0-9.e]+(npc|native)$", s))) return(NULL)
  v <- suppressWarnings(as.numeric(sub("(npc|native)$", "", s)))
  if (any(!is.finite(v))) NULL else v
}

# Where a text grob anchors horizontally: 0 is left-justified, so the words run
# to the right of the anchor.
text_hjust <- function(tg) {
  h <- tg$hjust
  if (is.null(h)) h <- tg$just
  if (is.character(h)) {
    k <- tolower(h[[1]])
    return(if (k == "right") 1 else if (k == "left") 0 else 0.5)
  }
  if (is.null(h)) return(0.5)
  v <- suppressWarnings(as.numeric(h))
  if (!length(v) || !is.finite(v[[1]])) 0.5 else min(v)
}

# Rightmost inch of any label drawn in the panel, from the panel's left edge.
# NA when there is nothing to measure.
panel_label_edge <- function(g, P) {
  row <- which(g$layout$name == "panel")
  if (length(row) != 1) return(NA_real_)
  worst <- -Inf
  for (tg in panel_text_grobs(g$grobs[[row]])) {
    if (length(tg$rot) && any(tg$rot != 0)) next
    x <- panel_position(tg$x)
    if (is.null(x)) next
    labs <- as.character(tg$label)
    if (!length(labs)) next
    w <- max(vapply(seq_along(labs), function(i) {
      gp <- tg$gp
      if (!is.null(gp))
        for (nm in names(gp)) if (length(gp[[nm]]) == length(labs)) gp[[nm]] <- gp[[nm]][i]
      text_width_in(labs[i], gp)
    }, numeric(1)))
    worst <- max(worst, max(x) * P + (1 - text_hjust(tg)) * w)
  }
  if (worst == -Inf) NA_real_ else worst
}

#' Rebuild a cell so its direct labels stay inside the panel
#'
#' Labels start at the last data point, so the only way to give them room is the
#' right-hand expansion: solve `(1 + ml) / (1 + ml + mr) * P + extent <= P - gap`
#' for `mr`, then rebuild and check. Returns the grob to draw plus a restore for
#' the x scale's expansion, which is borrowed for the duration of the draw (the
#' chart belongs to the caller).
#' @noRd
fit_direct_labels <- function(p, g) {
  nothing <- list(grob = g, restore = NULL)
  # Facets and non-Cartesian coords draw each panel in its own viewport, so a
  # position in [0, 1] is not a fraction of the panel column.
  coord <- p$coordinates
  if (!inherits(p$facet, "FacetNull") ||
      (!is.null(coord) && !inherits(coord, "CoordCartesian"))) return(nothing)
  cell_w <- device_width_in()
  if (!is.finite(cell_w) || cell_w <= 0) return(nothing)
  sc <- NULL
  for (s in p$scales$scales)
    if (inherits(s, "ScaleContinuous") && "x" %in% s$aesthetics) { sc <- s; break }
  if (is.null(sc)) return(nothing)
  orig <- sc$expand
  base <- if (is.numeric(orig) && length(orig) >= 4) orig else c(0.05, 0, 0.05, 0)
  cur <- base
  out <- g
  for (attempt in 1:3) {
    P <- panel_width_in(out, cell_w)
    edge <- if (is.finite(P) && P > 0.5) panel_label_edge(out, P) else NA_real_
    if (!is.finite(edge)) break
    extent <- edge - (1 + cur[1]) / (1 + cur[1] + cur[3]) * P
    room <- (P - label_gap_in - extent) / P
    if (!is.finite(room) || room <= 0.15) break
    mr <- min((1 + cur[1]) / room - 1 - cur[1], label_expand_max)
    if (mr <= cur[3] + 0.005) break
    cur[3] <- mr
    sc$expand <- cur
    out <- ggplot2::ggplotGrob(p)
  }
  list(grob = out, restore = local({ s <- sc; e <- orig; function() s$expand <- e }))
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
    function() { grid::grid.draw(labels_that_fit(x)$grob); draw_deco(x) },
    function() {
      restore <- blank_layer_fonts(x); on.exit(restore())
      y <- strip_font(x); grid::grid.draw(labels_that_fit(y)$grob); draw_deco(y)
    })
  invisible(x)
}

#' @export
print.panel_plot <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  grid::grid.draw(x)
  invisible(x)
}
