# Smart axes and smart text.
#
# Axes: numbers switch units by themselves (950, 1.2k, 3.4M) with one consistent
# precision per axis, percentages are detected, and dates carry the year only
# where it changes. Text: headlines are computed from the plotted table (what
# moved, who leads, who overtook whom) and the subtitle says in plain English
# what was calculated. Pass `title`/`subtitle` to override, or set
# `options(panelviz.smart_titles = FALSE)` for the plain variable name.

# ---- numbers -----------------------------------------------------------------

is_percent_var <- function(var, values, fun_group = "mean") {
  if (identical(fun_group, "share")) return(TRUE)
  v <- values[is.finite(values)]
  length(v) > 0 && length(var) == 1 &&
    grepl("(rate|share|pct|percent|proportion|prob|ratio)", var, ignore.case = TRUE) &&
    all(v >= -1.0001 & v <= 1.0001)
}

#' Axis label function for a variable: percent, or short numbers (1.2k, 3M)
#' @noRd
axis_labeller <- function(var, values, fun_group = "mean") {
  if (is_percent_var(var, values, fun_group)) return(scales::label_percent())
  scales::label_number(scale_cut = scales::cut_short_scale(), style_negative = "minus")
}

#' Format single numbers for text and data labels
#' @noRd
fmt_num <- function(x, var = NULL, fun_group = "mean", values = x) {
  if (!is.null(var) && is_percent_var(var, values, fun_group))
    return(scales::label_percent(accuracy = 0.1)(x))
  vapply(x, function(z) {
    if (is.na(z)) return("NA")
    a <- abs(z)
    if (a >= 1e3) return(scales::label_number(accuracy = 0.1, scale_cut = scales::cut_short_scale(), style_negative = "minus")(z))
    s <- format(signif(z, 3), trim = TRUE, scientific = FALSE, drop0trailing = TRUE)
    sub("-", "\u2212", s, fixed = TRUE)
  }, character(1), USE.NAMES = FALSE)
}

# ---- dates -------------------------------------------------------------------

#' Single-line period text (captions and headlines)
#' @noRd
period_text <- function(freq) {
  switch(freq,
    all = function(d) "all periods",
    hour = function(d) format(d, "%d %b %Y %H:%M"),
    year = function(d) format(d, "%Y"),
    quarter = function(d) paste0(format(d, "%Y"), " Q", (as.integer(format(d, "%m")) - 1L) %/% 3L + 1L),
    month = function(d) format(d, "%b %Y"),
    function(d) format(d, "%d %b %Y"))
}

#' Axis date labels: the year appears only where it changes
#' @noRd
period_labels <- function(freq) {
  with_year <- function(base, d, unit = "%Y") {
    yr <- format(d, unit)
    changed <- c(TRUE, yr[-1] != yr[-length(yr)])
    ifelse(changed, paste0(base, "\n", yr), base)
  }
  switch(freq,
    all = function(d) "All periods",
    year = function(d) format(d, "%Y"),
    quarter = function(d) with_year(paste0("Q", (as.integer(format(d, "%m")) - 1L) %/% 3L + 1L), d),
    month = function(d) with_year(format(d, "%b"), d),
    hour = function(d) with_year(format(d, "%H:%M"), d, "%d %b"),
    function(d) with_year(format(d, "%d %b"), d))
}

# ---- words -------------------------------------------------------------------

sentence_case <- function(x) paste0(toupper(substr(x, 1, 1)), substring(x, 2))

# Lower-case a label for mid-sentence use unless it has its own capitals (lifeExp, GDP).
lower_first <- function(x) {
  tok <- sub("[^A-Za-z0-9].*$", "", x)
  keep <- grepl("[A-Z]", substring(tok, 2))
  ifelse(keep, x, paste0(tolower(substr(x, 1, 1)), substring(x, 2)))
}

# Numeric group codes read better with their column name ("company 6").
group_name <- function(g, by) if (!is.null(by) && length(by) == 1 && grepl("^-?[0-9.]+$", g)) paste(tolower(by), g) else g

var_label <- function(var, info) {
  lab <- info$labels[[var]]
  if (is.character(lab) && length(lab) == 1 && nzchar(lab)) sentence_case(lab) else pretty_name(var)
}

stat_phrase <- function(f) {
  if (!is.character(f)) return("Summary of")
  if (grepl("^p[0-9]+$", f)) {
    n <- as.integer(sub("^p", "", f))
    suf <- if (n %% 100 %in% 11:13) "th" else switch(as.character(n %% 10), "1" = "st", "2" = "nd", "3" = "rd", "th")
    return(sprintf("%d%s percentile of", n, suf))
  }
  switch(f, mean = "Average", median = "Median", sum = "Total", sd = "Standard deviation of",
         min = "Lowest", max = "Highest", first = "First value of", last = "Latest value of",
         n = "Number of observations of", share = "Share of individuals with positive",
         sentence_case(f))
}

stat_noun <- function(f) {   # inside "(each individual's ___ per year)"
  if (!is.character(f)) return("value")
  switch(f, mean = "average", median = "median", sum = "total", min = "minimum", max = "maximum",
         first = "first value", last = "latest value", n = "count", sd = "standard deviation", f)
}

freq_adverb <- function(freq) {
  switch(freq, year = "yearly", quarter = "quarterly", month = "monthly", week = "weekly",
         day = "daily", hour = "hourly", all = "all periods combined", NULL)
}

#' Plain-English subtitle: what was calculated
#' @noRd
plain_subtitle <- function(var, info, by = NULL, period = NULL, fun_time = "mean", fun_group = "mean",
                           index = FALSE, vars = var) {
  what <- if (length(vars) > 1) "measures" else var_label(var, info)
  if (length(vars) == 1) what <- lower_first(what)
  else if (length(vars) <= 3) what <- paste(vars, collapse = " + ")
  txt <- paste0(stat_phrase(fun_group), " ", what,
                if (!is.null(by)) paste0(" by ", paste(tolower(gsub("[_.]+", " ", by)), collapse = " and ")) else
                  " across all individuals")
  fq <- if (identical(period, "all")) NULL else info$freq
  bits <- c(freq_adverb(fq %||% ""),
            if (!is.null(period) && !identical(period, "all"))
              sprintf("after taking each individual's %s per %s", stat_noun(fun_time), period),
            if (index) "indexed: first period = 100")
  if (length(bits)) txt <- paste0(txt, " \u00b7 ", paste(bits, collapse = ", "))
  txt
}

# ---- headlines ---------------------------------------------------------------

change_phrase <- function(label, first, last, ptxt, var = NULL, fun_group = "mean", values = c(first, last)) {
  if (is.na(first) || is.na(last)) return(label)
  span <- sprintf("between %s and %s", ptxt[1], ptxt[2])
  if (isTRUE(first == 0)) return(sprintf("%s rose from 0 to %s %s", label, fmt_num(last, var, fun_group, values), span))
  r <- last / first
  if (first > 0 && r >= 100) return(sprintf("%s grew from %s to %s %s", label, fmt_num(first, var, fun_group, values), fmt_num(last, var, fun_group, values), span))
  if (first > 0 && r >= 2) return(sprintf("%s %s %s", label, if (r >= 3) sprintf("rose %s-fold", format(round(r, 1), drop0trailing = TRUE)) else "more than doubled", span))
  if (first > 0 && r <= 0.5) return(sprintf("%s fell by more than half %s", label, span))
  pct <- (last - first) / abs(first)
  if (abs(pct) < 0.02) return(sprintf("%s was broadly flat %s", label, span))
  sprintf("%s %s %s %s", label, if (pct > 0) "rose" else "fell", scales::percent(abs(pct), accuracy = 1), span)
}

ends_of <- function(tab, var) {
  t <- tab[order(tab$.period), ]
  t <- t[!is.na(t[[var]]), ]
  list(first = t[[var]][1], last = t[[var]][nrow(t)], p = c(t$.period[1], t$.period[nrow(t)]))
}

#' Headline computed from the plotted table
#' @noRd
smart_headline <- function(kind, tab, var, by, info, fun_group = "mean", opts = list()) {
  lab <- var_label(var[1], info)
  fq <- if (identical(info$freq, "all")) info$freq_native else info$freq
  pt <- function(p) if (info$kind == "index") format(p) else period_text(fq)(p)
  vals <- tab[[var[1]]]
  groups <- if (".group" %in% names(tab)) unique(tab$.group) else "All"

  if (kind %in% c("line", "spaghetti", "tracking", "band") && length(groups) == 1) {
    v <- if (kind == "band") ".mid" else var[1]
    e <- ends_of(tab, v)
    h <- change_phrase(lab, e$first, e$last, pt(e$p), var[1], fun_group, vals)
    if (kind == "band" && !is.null(tab$.lo)) {
      t <- tab[order(tab$.period), ]; w <- t$.hi - t$.lo; w <- w[!is.na(w)]
      if (length(w) > 1 && w[1] > 0) {
        ch <- (w[length(w)] - w[1]) / w[1]
        if (abs(ch) >= 0.1) h <- paste0(h, sprintf("; the spread %s by %s", if (ch > 0) "widened" else "narrowed", scales::percent(abs(ch), accuracy = 1)))
      }
    }
    if (kind == "tracking" && !is.null(opts$window)) h <- paste0(h, "")
    return(h)
  }

  if (kind %in% c("line", "spaghetti", "band") && length(groups) > 1) {
    v <- if (kind == "band") ".mid" else var[1]
    first_p <- min(tab$.period); last_p <- max(tab$.period)
    at <- function(p) { z <- tab[tab$.period == p & !is.na(tab[[v]]), ]; z[order(z[[v]], decreasing = TRUE), ] }
    a <- at(first_p); b <- at(last_p)
    if (nrow(b) >= 2) {
      if (nrow(a) >= 1 && a$.group[1] != b$.group[1] && a$.group[1] %in% b$.group)
        return(sprintf("%s overtook %s as the highest on %s by %s", sentence_case(group_name(b$.group[1], by)), group_name(a$.group[1], by), lower_first(lab), pt(last_p)))
      top <- b[1, ]; bot <- b[nrow(b), ]
      ratio <- if (bot[[v]] > 0) top[[v]] / bot[[v]] else NA
      if (!is.na(ratio) && ratio >= 1.2 && ratio < 10 && !is_percent_var(var[1], vals, fun_group))
        return(sprintf("%s is highest on %s, %s the level of %s", sentence_case(group_name(top$.group, by)), lower_first(lab),
                       sprintf("%s times", format(round(ratio, 1), drop0trailing = TRUE)), group_name(bot$.group, by)))
      return(sprintf("%s leads on %s at %s, %s trails at %s", sentence_case(group_name(top$.group, by)), lower_first(lab),
                     fmt_num(top[[v]], var[1], fun_group, vals), group_name(bot$.group, by), fmt_num(bot[[v]], var[1], fun_group, vals)))
    }
  }

  if (kind == "heatmap") {
    i <- which.max(vals)
    if (length(i) == 1 && !is.na(vals[i])) {
      g <- if (".group" %in% names(tab)) as.character(tab$.group[i]) else NULL
      return(sprintf("%s peaks %s in %s at %s", lab, if (!is.null(g) && !isTRUE(opts$rows_are_ids)) paste("for", g) else "", pt(tab$.period[i]), fmt_num(vals[i], var[1], fun_group, vals)) |> gsub(pattern = "  ", replacement = " "))
    }
  }

  if (kind == "bar" && nrow(tab) >= 2) {
    t <- tab[order(tab[[var[1]]], decreasing = TRUE), ]
    return(sprintf("%s leads on %s at %s; %s trails at %s", sentence_case(group_name(t$.group[1], by)), lower_first(lab), fmt_num(t[[var[1]]][1], var[1], fun_group, vals),
                   group_name(t$.group[nrow(t)], by), fmt_num(t[[var[1]]][nrow(t)], var[1], fun_group, vals)))
  }

  if (kind == "stacked" && !is.null(tab$.measure)) {
    tot <- tab[!duplicated(tab$.group), ]
    top <- tot$.group[which.max(tot$.total)]
    parts <- tab[tab$.group == top, ]
    big <- parts[which.max(parts$.value), ]
    return(sprintf("%s has the largest total, %s of it from %s", sentence_case(group_name(top, by)), scales::percent(big$.value / sum(parts$.value), accuracy = 1), tolower(as.character(big$.measure))))
  }

  if (kind == "distribution") {
    q <- stats::quantile(vals, c(0.1, 0.5, 0.9), na.rm = TRUE)
    return(sprintf("Most individuals sit between %s and %s on %s (median %s)", fmt_num(q[[1]], var[1], "mean", vals), fmt_num(q[[3]], var[1], "mean", vals), lower_first(lab), fmt_num(q[[2]], var[1], "mean", vals)))
  }
  lab
}

#' Title and subtitle for a chart
#'
#' Both are returned as plain strings: the line breaks depend on the device the
#' chart is drawn on, so [wrap_to_width()] puts them in when the chart is drawn.
#' @noRd
smart_text <- function(kind, tab, var, by, period, fun_time, fun_group, info, opts = list()) {
  plain <- identical(getOption("panelviz.smart_titles"), FALSE)
  sub <- if (isTRUE(opts$rows_are_ids)) "Each row is an individual" else if (!is.null(opts$subtitle)) opts$subtitle else
    plain_subtitle(var[1], info, by, period, fun_time, fun_group, isTRUE(opts$index), vars = var)
  if (is.null(opts$subtitle) && !isTRUE(opts$rows_are_ids) && !is.null(opts$n) && length(opts$n) > 1 && max(opts$n) > 1) {
    r <- range(opts$n)
    per <- if (!is.null(by) && length(by) == 1) tolower(gsub("[_.]+", " ", by)) else "group"
    sub <- paste0(sub, " \u00b7 ", if (r[1] == r[2]) sprintf("%s individual%s per %s", format(r[1], big.mark = ","), if (r[1] == 1) "" else "s", per)
                  else sprintf("%s to %s individuals per %s", format(r[1], big.mark = ","), format(r[2], big.mark = ","), per))
  }
  ttl <- if (plain) var_label(var[1], info) else
    tryCatch(smart_headline(kind, tab, var, by, info, fun_group, opts), error = function(e) var_label(var[1], info))
  list(title = ttl, subtitle = sub)
}
