# Plotting. Every plot function aggregates with panel_aggregate() first, so the
# same `by`, `period`, `fun_time`, `fun_group` and `min_n` arguments apply
# everywhere, and `return = "table"` hands back exactly what is drawn.

# Tiles slightly wider than the shortest period so uneven month/quarter lengths leave no gaps.
tile_width <- function(info) {
  switch(info$freq, year = 367, quarter = 93, month = 32, week = 7.2, day = 1.05, NULL)
}

# Breaks sit on real periods (thinned to at most `n`), so labels always match the data.
period_breaks <- function(periods, n = 8, freq = NULL) {
  u <- sort(unique(periods))
  if (length(u) <= n) return(u)
  step <- ceiling(length(u) / n)
  start <- 1
  if (identical(freq, "quarter") || identical(freq, "month")) {
    per_year <- if (freq == "quarter") 4 else 12
    step <- if (step < per_year) c(1, 2, 3, 4, 6, 12)[c(1, 2, 3, 4, 6, 12) >= step][1] else per_year * ceiling(step / per_year)
    jan <- which(format(u, "%m") == "01")
    if (length(jan)) start <- jan[1] - step * ((jan[1] - 1) %/% step)
    if (start < 1) start <- jan[1]
  }
  u[seq(start, length(u), by = step)]
}

# Value axis with short labels (6 M instead of 6e+06).
y_scale <- function(log = FALSE, labeller = NULL, position = "right") {
  lab <- labeller %||% scales::label_number(scale_cut = scales::cut_short_scale(), style_negative = "minus")
  if (log) ggplot2::scale_y_log10(labels = lab, position = position) else ggplot2::scale_y_continuous(labels = lab, position = position)
}

time_scale <- function(info, periods, expand = ggplot2::waiver(), position = "bottom") {
  if (info$kind == "index")
    ggplot2::scale_x_continuous(expand = expand, breaks = scales::breaks_pretty(7), position = position,
                                labels = function(z) format(z, scientific = FALSE, trim = TRUE))
  else if (info$kind == "hour")
    ggplot2::scale_x_datetime(expand = expand, breaks = period_breaks(periods, freq = "hour"),
                              labels = period_labels("hour"), position = position)
  else
    ggplot2::scale_x_date(expand = expand, breaks = period_breaks(periods, freq = info$freq),
                          labels = period_labels(info$freq), position = position)
}

caption_for <- function(tab, info, var_note = NULL) {
  fq <- if (identical(info$freq, "all")) info$freq_native else info$freq
  rng <- if (info$kind == "index") paste(info$range, collapse = " to ") else
    paste(period_text(fq)(info$range), collapse = " to ")
  paste0(c(var_note, sprintf("%s individuals, %s", format(info$n_ids, big.mark = ","), rng),
           if (!is.null(info$min_n)) sprintf("groups under %d individuals hidden", info$min_n)), collapse = " | ")
}

summary_note <- function(fun_group, by) {
  f <- if (is.character(fun_group)) fun_group else "custom summary"
  if (is.null(by)) sprintf("%s across all individuals", f) else sprintf("%s by %s", f, paste(by, collapse = " x "))
}

group_col <- function(tab, by) {
  if (is.null(by)) return(rep("All", nrow(tab)))
  do.call(paste, c(unname(as.list(tab[by])), sep = " | "))
}

#' Line chart of a panel variable over time
#'
#' One line per group (or one overall line), labelled directly at the end of
#' each line.
#'
#' @param x A `tidy_panel`.
#' @param var The variable to plot.
#' @inheritParams panel_aggregate
#' @param facet Draw one panel per group instead of overlaying lines.
#' @param highlight Group name(s) to emphasise; all others turn grey.
#' @param index Rebase every group so its first period equals 100.
#' @param log Use a log10 value axis.
#' @param max_groups Keep only this many groups (largest by individuals).
#' @param tag Optional figure number or label, drawn in a square at the top right.
#' @param return `"plot"` or `"table"`.
#' @param title,subtitle Optional text; defaults are generated.
#' @return A ggplot (or the plotted table).
#' @export
panel_line <- function(x, var, by = NULL, period = NULL, fun_time = "mean", fun_group = "mean",
                       min_n = NULL, facet = FALSE, max_groups = 10, highlight = NULL, index = FALSE,
                       log = FALSE, tag = NULL, return = c("plot", "table"), title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  tab <- panel_aggregate(x, var, by = by, period = period, fun_time = fun_time,
                         fun_group = fun_group, min_n = min_n)
  info <- attr(tab, "panel_info")
  tab$.group <- group_col(tab, by)
  tab <- limit_groups(tab, max_groups)
  if (index) {
    tab <- tab[order(tab$.group, tab$.period), ]
    tab[[var]] <- stats::ave(tab[[var]], tab$.group, FUN = function(z) 100 * z / z[which(!is.na(z))[1]])
  }
  if (return == "table") return(tab)
  txt <- smart_text("line", tab, var, by, period, fun_time, fun_group, info, list(index = index))

  lab_end <- do.call(rbind, lapply(split(tab, tab$.group), function(g) g[which.max(g$.period), ]))
  if (!is.null(highlight)) lab_end <- lab_end[lab_end$.group %in% highlight, ]
  lab_end$.y <- spread_labels(lab_end[[var]], diff(range(tab[[var]], na.rm = TRUE)) * 0.045)
  many <- length(unique(tab$.group)) > 1 && !facet
  p <- ggplot2::ggplot(tab, ggplot2::aes(.data$.period, .data[[var]], colour = .data$.group, group = .data$.group)) +
    ggplot2::geom_line(linewidth = 1.3, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = group_colours(tab$.group, highlight)) +
    time_scale(info, tab$.period, expand = ggplot2::expansion(mult = c(0.02, if (many) 0.18 else 0.04))) +
    y_scale(log, axis_labeller(var, tab[[var]], fun_group)) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info, if (index) paste0("Indexed: first period = 100"))) +
    panel_style(tag)
  if (many) p <- p + ggplot2::geom_text(data = lab_end, ggplot2::aes(y = .data$.y, label = .data$.group),
                                        hjust = 0, nudge_x = label_nudge(tab, info), size = 3.6,
                                        fontface = "bold", show.legend = FALSE)
  if (facet) p <- p + ggplot2::facet_wrap(ggplot2::vars(.data$.group), scales = "free_y")
  p
}

#' Heatmap of groups (rows) by time (columns)
#'
#' @inheritParams panel_line
#' @param max_rows When `by` is `NULL` rows are individuals; show this many
#'   (evenly spaced after sorting by level).
#' @param diverge Use a diverging blue-white-red scale centred on the overall mean.
#' @param palette Vector of colours for the sequential scale.
#' @export
panel_heatmap <- function(x, var, by = NULL, period = NULL, fun_time = "mean", fun_group = "mean",
                          min_n = NULL, max_rows = 40, diverge = FALSE,
                          palette = c("#eef5f9", "#b5dcee", "#00a0dc", "#00587a", "#00293d"),
                          tag = NULL, return = c("plot", "table"), title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  rows_are_ids <- is.null(by)
  by_use <- if (rows_are_ids) ".id" else by
  tab <- panel_aggregate(x, var, by = by_use, period = period, fun_time = fun_time,
                         fun_group = fun_group, min_n = min_n)
  info <- attr(tab, "panel_info")
  tab$.group <- group_col(tab, by_use)
  ord <- tapply(tab[[var]], tab$.group, mean, na.rm = TRUE)
  ord <- ord[order(ord, decreasing = TRUE)]
  if (length(ord) > max_rows) {
    keep <- ord[unique(round(seq(1, length(ord), length.out = max_rows)))]
    cli::cli_inform("Showing {length(keep)} of {length(ord)} rows (evenly spaced by level); raise {.arg max_rows} to see more.")
    ord <- keep; tab <- tab[tab$.group %in% names(ord), ]
  }
  tab$.group <- factor(tab$.group, levels = rev(names(ord)))
  if (return == "table") return(tab)
  txt <- smart_text("heatmap", tab, var, by, period, fun_time, fun_group, info, list(rows_are_ids = rows_are_ids))

  scale <- if (diverge) {
    mid <- mean(tab[[var]], na.rm = TRUE)
    ggplot2::scale_fill_gradient2(low = "#00587a", mid = "white", high = "#e3120b", midpoint = mid, name = NULL, labels = axis_labeller(var, tab[[var]], fun_group))
  } else ggplot2::scale_fill_gradientn(colours = palette, name = NULL, labels = axis_labeller(var, tab[[var]], fun_group))
  tw <- tile_width(info)
  tile_layer <- if (length(unique(tab$.period)) > 30 && !is.null(tw)) ggplot2::geom_tile(colour = NA, width = tw) else
    ggplot2::geom_tile(colour = "white", linewidth = 0.3)
  ggplot2::ggplot(tab, ggplot2::aes(.data$.period, .data$.group, fill = .data[[var]])) +
    tile_layer +
    scale +
    time_scale(info, tab$.period, expand = ggplot2::expansion(mult = 0.01), position = "top") +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = 0.5)) +
    ggplot2::guides(fill = ggplot2::guide_colourbar(barwidth = grid::unit(12, "lines"),
                                                     barheight = grid::unit(0.5, "lines"))) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}

#' Individual trajectories with the group average on top
#'
#' @inheritParams panel_line
#' @param n_ids Draw at most this many individual lines (random, reproducible).
#' @param seed Seed for the individual sample.
#' @param log Use a log10 value axis (helps when individuals differ in scale).
#' @export
panel_spaghetti <- function(x, var, by = NULL, period = NULL, fun_time = "mean", fun_group = "mean",
                            n_ids = 100, seed = 1, log = FALSE, tag = NULL, return = c("plot", "table"),
                            title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  ind <- panel_aggregate(x, var, by = unique(c(".id", by)), period = period, fun_time = fun_time)
  avg <- panel_aggregate(x, var, by = by, period = period, fun_time = fun_time, fun_group = fun_group)
  info <- attr(avg, "panel_info")
  ind$.group <- group_col(ind, by); avg$.group <- group_col(avg, by)
  ids <- unique(ind$.id)
  if (length(ids) > n_ids) {
    old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv())
    set.seed(seed); ids <- sample(ids, n_ids)
    if (!is.null(old)) assign(".Random.seed", old, globalenv())
  }
  ind <- ind[ind$.id %in% ids, ]
  if (return == "table") return(list(individuals = ind, average = avg))
  txt <- smart_text("spaghetti", avg, var, by, period, fun_time, fun_group, info, list(subtitle = sprintf("%d individual trajectories (thin) and the %s (bold)", length(ids), if (is.character(fun_group)) fun_group else "summary")))

  multi <- length(unique(avg$.group)) > 1
  cols <- rep_len(panel_colours, length(unique(avg$.group))); names(cols) <- sort(unique(avg$.group))
  base_aes <- ggplot2::aes(.data$.period, .data[[var]])
  layers <- if (multi) list(
    ggplot2::geom_line(data = ind, ggplot2::aes(group = .data$.id, colour = .data$.group),
                       alpha = 0.18, linewidth = 0.4),
    ggplot2::geom_line(data = avg, ggplot2::aes(group = .data$.group, colour = .data$.group), linewidth = 1.6),
    ggplot2::scale_colour_manual(values = cols, name = NULL)
  ) else list(
    ggplot2::geom_line(data = ind, ggplot2::aes(group = .data$.id), colour = "#00405c",
                       alpha = 0.22, linewidth = 0.4),
    ggplot2::geom_line(data = avg, ggplot2::aes(group = .data$.group), colour = "#e3120b", linewidth = 1.8)
  )
  ggplot2::ggplot(mapping = base_aes) +
    layers +
    time_scale(info, avg$.period, expand = ggplot2::expansion(mult = 0.02)) +
    y_scale(log, axis_labeller(var, avg[[var]], fun_group)) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(avg, info)) +
    panel_style(tag)
}

#' Plot a panel with a chosen chart type
#' @param kind One of `"line"`, `"heatmap"`, `"spaghetti"`, `"tracking"`, `"band"`,
#'   `"bar"`, `"stacked"`, `"distribution"`. For `"stacked"`, `var` is a vector of columns.
#' @param ... Passed to the chart function.
#' @inheritParams panel_line
#' @export
panel_plot <- function(x, var, kind = c("line", "heatmap", "spaghetti", "tracking", "band", "bar", "stacked", "distribution"), ...) {
  kind <- match.arg(kind)
  switch(kind, line = panel_line(x, var, ...), heatmap = panel_heatmap(x, var, ...),
         spaghetti = panel_spaghetti(x, var, ...), tracking = panel_tracking(x, var, ...),
         band = panel_band(x, var, ...), bar = panel_bar(x, var, ...),
         stacked = panel_stacked(x, var, ...), distribution = panel_distribution(x, var, ...))
}

# Named colours per group; with `highlight`, everything else is grey.
group_colours <- function(groups, highlight = NULL) {
  g <- sort(unique(groups))
  if (is.null(highlight)) return(stats::setNames(rep_len(panel_colours, length(g)), g))
  stats::setNames(ifelse(g %in% highlight, panel_colours[2], "#c9c9c9"), g)
}

pretty_name <- function(v) {
  v <- gsub("([a-z])([A-Z])", "\\1 \\2", v)
  v <- gsub("[_.]+", " ", v)
  if (grepl("[a-z]", v)) v <- paste0(substr(v, 1, 1), tolower(substring(v, 2)))
  paste0(toupper(substr(v, 1, 1)), substring(v, 2))
}

pretty_summary <- function(fun_group, by, period, info, fun_time = "mean") {
  f <- if (is.character(fun_group)) fun_group else "Summary"
  f <- paste0(toupper(substr(f, 1, 1)), substring(f, 2))
  txt <- paste0(f, if (!is.null(by)) paste0(" by ", paste(by, collapse = " x ")) else " across individuals")
  if (!is.null(period)) txt <- paste0(txt, ", per ", period,
    if (is.character(fun_time)) paste0(" (each individual's ", fun_time, " within the ", period, ")") else "")
  txt
}

limit_groups <- function(tab, max_groups) {
  g <- unique(tab$.group)
  if (length(g) <= max_groups) return(tab)
  cnt <- tapply(tab$.n, tab$.group, max)
  keep <- names(sort(cnt, decreasing = TRUE))[seq_len(max_groups)]
  cli::cli_inform("Showing the {max_groups} largest of {length(g)} groups; raise {.arg max_groups} to see more.")
  tab[tab$.group %in% keep, ]
}

# Push sorted label positions apart so direct labels do not collide.
spread_labels <- function(y, gap) {
  o <- order(y); z <- y[o]
  for (i in seq_along(z)[-1]) if (z[i] - z[i - 1] < gap) z[i] <- z[i - 1] + gap
  shift <- mean(y[o]) - mean(z); y[o] <- z + shift
  y
}

label_nudge <- function(tab, info) {
  span <- as.numeric(diff(range(tab$.period)))
  span * 0.01
}

# ---- more charts -------------------------------------------------------------

#' Tracking chart: the period average with a rolling average
#'
#' @inheritParams panel_line
#' @param window Number of periods in the (trailing) rolling average.
#' @export
panel_tracking <- function(x, var, period = NULL, fun_time = "mean", fun_group = "mean",
                           window = 4, min_n = NULL, tag = NULL, return = c("plot", "table"),
                           title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  tab <- panel_aggregate(x, var, period = period, fun_time = fun_time, fun_group = fun_group, min_n = min_n)
  info <- attr(tab, "panel_info")
  tab <- tab[order(tab$.period), ]
  v <- tab[[var]]
  roll <- vapply(seq_along(v), function(i) mean(v[max(1, i - window + 1):i], na.rm = TRUE), numeric(1))
  long <- rbind(
    data.frame(.period = tab$.period, series = "Period average", value = v),
    data.frame(.period = tab$.period, series = sprintf("%d-period rolling average", window), value = roll))
  long$series <- factor(long$series, levels = unique(long$series))
  if (return == "table") return(tibble::as_tibble(long))
  txt <- smart_text("tracking", tab, var, NULL, period, fun_time, fun_group, info, list(window = window))
  ggplot2::ggplot(long, ggplot2::aes(.data$.period, .data$value, colour = .data$series)) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::scale_colour_manual(values = c("#00a0dc", "#00405c"), name = NULL) + y_scale(labeller = axis_labeller(var, tab[[var]], fun_group)) +
    time_scale(info, long$.period, expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag)
}

#' Median with an inter-quantile band across individuals
#'
#' Shows the spread of individuals, not just the average.
#'
#' @inheritParams panel_line
#' @param lower,upper Band edges as percentile names (`"p25"`, `"p75"`, `"p10"`, `"p90"`).
#' @param centre Centre line summary (default `"median"`).
#' @export
panel_band <- function(x, var, by = NULL, period = NULL, fun_time = "mean",
                       lower = "p25", upper = "p75", centre = "median", min_n = NULL,
                       max_groups = 6, tag = NULL, return = c("plot", "table"), title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  one <- function(f, nm) {
    t <- panel_aggregate(x, var, by = by, period = period, fun_time = fun_time, fun_group = f, min_n = min_n)
    names(t)[names(t) == var] <- nm; t
  }
  lo <- one(lower, ".lo"); hi <- one(upper, ".hi"); mid <- one(centre, ".mid")
  keys <- c(".period", by)
  tab <- Reduce(function(a, b) dplyr::left_join(a, b[c(keys, setdiff(names(b), names(a)))], by = keys), list(mid, lo, hi))
  info <- attr(mid, "panel_info")
  tab$.group <- group_col(tab, by)
  tab <- limit_groups(tab, max_groups)
  if (return == "table") return(tab)
  txt <- smart_text("band", tab, var, by, period, fun_time, "median", info, list(subtitle = sprintf("Median line, shaded %s to %s across individuals", lower, upper)))
  multi <- length(unique(tab$.group)) > 1
  cols <- rep_len(panel_colours, length(unique(tab$.group))); names(cols) <- sort(unique(tab$.group))
  ggplot2::ggplot(tab, ggplot2::aes(.data$.period, group = .data$.group, colour = .data$.group, fill = .data$.group)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = .data$.lo, ymax = .data$.hi), alpha = 0.18, colour = NA) +
    ggplot2::geom_line(ggplot2::aes(y = .data$.mid), linewidth = 1.2) +
    ggplot2::scale_colour_manual(values = cols, name = NULL) + ggplot2::scale_fill_manual(values = cols, name = NULL) +
    y_scale(labeller = axis_labeller(var, tab$.mid, "mean")) + time_scale(info, tab$.period, expand = ggplot2::expansion(mult = 0.02)) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag) + ggplot2::theme(legend.position = if (multi) "top" else "none")
}

#' Ranked bars of groups
#'
#' Time is collapsed (`period = "all"`) unless you give a period, in which case
#' the latest period is shown. Group sizes appear in the labels.
#' @inheritParams panel_line
#' @param top_n Keep this many groups.
#' @param decreasing Sort largest first.
#' @export
panel_bar <- function(x, var, by, period = "all", fun_time = "mean", fun_group = "mean",
                      min_n = NULL, top_n = 15, decreasing = TRUE, tag = NULL, return = c("plot", "table"),
                      title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  tab <- panel_aggregate(x, var, by = by, period = period, fun_time = fun_time, fun_group = fun_group, min_n = min_n)
  info <- attr(tab, "panel_info")
  tab <- tab[tab$.period == max(tab$.period), ]
  tab$.group <- group_col(tab, by)
  tab <- tab[order(tab[[var]], decreasing = decreasing), ]
  tab <- utils::head(tab, top_n)
  tab$.label <- factor(tab$.group, levels = rev(tab$.group))
  if (return == "table") return(tab)
  txt <- smart_text("bar", tab, var, by, period, fun_time, fun_group, info, list(n = tab$.n))
  v <- tab[[var]]; vmax <- max(abs(v), na.rm = TRUE)
  inside <- abs(v) >= 0.4 * vmax
  val <- fmt_num(v, var, fun_group, v)
  # names sit inside long bars; on short bars they move outside, next to the value
  tab$.name <- ifelse(inside, as.character(tab$.group), "")
  tab$.end <- ifelse(inside, val, paste(tab$.group, val, sep = "  "))
  ggplot2::ggplot(tab, ggplot2::aes(.data[[var]], .data$.label)) +
    ggplot2::geom_col(fill = econ[["cyan"]], width = 0.78) +
    ggplot2::geom_text(ggplot2::aes(x = 0, label = .data$.name), hjust = 0, nudge_x = vmax * 0.012,
                       colour = "white", fontface = "bold", size = 4.2, family = panel_font()) +
    ggplot2::geom_text(ggplot2::aes(label = .data$.end), hjust = -0.08, colour = ink, size = 4.1, family = panel_font()) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.22)), position = "top",
                                labels = axis_labeller(var, v, fun_group)) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag) +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(), axis.text.y = ggplot2::element_blank(),
                   axis.line.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank(),
                   panel.grid.major.x = ggplot2::element_line(colour = "white", linewidth = 0.7))
}

#' Stacked bars: how several measures add up within each group
#'
#' @inheritParams panel_bar
#' @param vars Two or more numeric columns that form the stack.
#' @param min_label Hide a segment's value label when it is thinner than this
#'   share of the longest bar (avoids overflowing labels).
#' @export
panel_stacked <- function(x, vars, by, period = "all", fun_time = "mean", fun_group = "mean",
                          min_n = NULL, top_n = 15, min_label = 0.05, tag = NULL, return = c("plot", "table"),
                          title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  tab <- panel_aggregate(x, vars, by = by, period = period, fun_time = fun_time, fun_group = fun_group, min_n = min_n)
  info <- attr(tab, "panel_info")
  tab <- tab[tab$.period == max(tab$.period), ]
  tab$.group <- group_col(tab, by)
  tab$.total <- rowSums(tab[vars], na.rm = TRUE)
  tab <- utils::head(tab[order(tab$.total, decreasing = TRUE), ], top_n)
  tab$.label <- factor(tab$.group, levels = rev(tab$.group))
  long <- tidyr::pivot_longer(tab, dplyr::all_of(vars), names_to = ".measure", values_to = ".value")
  long$.measure <- factor(long$.measure, levels = rev(vars))
  if (return == "table") return(long)
  txt <- smart_text("stacked", long, vars, by, period, fun_time, fun_group, info, list(n = tab$.n))
  cols <- stats::setNames(rev(rep_len(unname(econ[c("cyan", "navy", "steel", "salmon", "amber", "green")]), length(vars))), rev(vars))
  cols <- cols[levels(long$.measure)]
  long$.show <- ifelse(long$.value >= min_label * max(tab$.total), fmt_num(long$.value), "")
  ggplot2::ggplot(long, ggplot2::aes(.data$.value, .data$.label, fill = .data$.measure)) +
    ggplot2::geom_col(width = 0.72, colour = "white", linewidth = 0.3) +
    ggplot2::geom_text(ggplot2::aes(label = .data$.show), position = ggplot2::position_stack(vjust = 0.5),
                       colour = "white", fontface = "bold", size = 4, family = panel_font()) +
    ggplot2::scale_fill_manual(values = cols, breaks = vars, name = NULL) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.03)), position = "top",
                                labels = axis_labeller(vars[1], long$.value, fun_group)) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag) + ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(), axis.line.x = ggplot2::element_blank(),
                                      axis.ticks.x = ggplot2::element_blank(),
                                      panel.grid.major.x = ggplot2::element_line(colour = "white", linewidth = 0.7))
}

#' Distribution of individuals
#'
#' Collapses time per individual (`fun_time`), then shows how individuals are
#' distributed, overall or by group.
#' @inheritParams panel_line
#' @export
panel_distribution <- function(x, var, by = NULL, period = "all", fun_time = "mean",
                               max_groups = 6, tag = NULL, return = c("plot", "table"), title = NULL, subtitle = NULL) {
  return <- match.arg(return)
  tab <- panel_aggregate(x, var, by = unique(c(".id", by)), period = period, fun_time = fun_time)
  info <- attr(tab, "panel_info")
  tab <- tab[tab$.period == max(tab$.period), ]
  tab$.group <- group_col(tab, by)
  tab <- limit_groups(tab, max_groups)
  if (return == "table") return(tab)
  txt <- smart_text("distribution", tab, var, by, period, fun_time, "mean", info, list(subtitle = sprintf("Distribution of individuals (each individual's %s over time)", stat_noun(fun_time))))
  multi <- length(unique(tab$.group)) > 1
  cols <- rep_len(panel_colours, length(unique(tab$.group))); names(cols) <- sort(unique(tab$.group))
  ggplot2::ggplot(tab, ggplot2::aes(.data[[var]], fill = .data$.group, colour = .data$.group)) +
    ggplot2::geom_density(alpha = if (multi) 0.25 else 0.6, linewidth = 0.8) +
    ggplot2::scale_fill_manual(values = cols, name = NULL) + ggplot2::scale_colour_manual(values = cols, name = NULL) +
    ggplot2::scale_x_continuous(labels = axis_labeller(var, tab[[var]], "mean")) +
    ggplot2::labs(title = title %||% txt$title,
                  subtitle = subtitle %||% txt$subtitle,
                  caption = caption_for(tab, info)) +
    panel_style(tag) + ggplot2::theme(axis.text.y = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank(),
                                   panel.grid.major.x = ggplot2::element_line(colour = "white", linewidth = 0.7),
                                   legend.position = if (multi) "top" else "none")
}
