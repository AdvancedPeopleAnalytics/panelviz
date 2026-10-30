# Aggregation is two stages, because panel data has two dimensions:
#   1. within each individual, collapse time into `period`   (fun_time)
#   2. across individuals, collapse them into `by` groups     (fun_group)
# e.g. daily hours -> weekly total per person (sum) -> mean per department.

agg_fun <- function(f) {
  if (is.function(f)) return(f)
  if (!is.character(f) || length(f) != 1) cli::cli_abort("A summary must be a function or a name like {.val mean}.")
  na_safe <- function(g) function(x) if (all(is.na(x))) NA_real_ else g(x)
  if (grepl("^p[0-9]+$", f)) {
    p <- as.numeric(sub("^p", "", f)) / 100
    return(na_safe(function(x) unname(stats::quantile(x, p, na.rm = TRUE))))
  }
  switch(f,
    mean = na_safe(function(x) mean(x, na.rm = TRUE)),
    median = na_safe(function(x) stats::median(x, na.rm = TRUE)),
    sum = na_safe(function(x) sum(x, na.rm = TRUE)),
    sd = na_safe(function(x) stats::sd(x, na.rm = TRUE)),
    min = na_safe(function(x) min(x, na.rm = TRUE)),
    max = na_safe(function(x) max(x, na.rm = TRUE)),
    first = function(x) { x <- x[!is.na(x)]; if (length(x)) x[1] else NA_real_ },
    last = function(x) { x <- x[!is.na(x)]; if (length(x)) x[length(x)] else NA_real_ },
    n = function(x) sum(!is.na(x)),
    share = na_safe(function(x) mean(x > 0, na.rm = TRUE)),
    cli::cli_abort("Unknown summary {.val {f}}. Use mean, median, sum, sd, min, max, first, last, n, share, a percentile like {.val p90}, or a function."))
}

#' Aggregate a panel over time and across individuals
#'
#' @param x A `tidy_panel` from [as_panel()].
#' @param vars Numeric columns to summarise; default all numeric columns.
#' @param by Grouping column(s) to aggregate individuals into (e.g. a region);
#'   `NULL` for one overall series. Use `".id"` to keep individuals.
#' @param period Coarsen time to `"hour"`, `"day"`, `"week"`, `"month"`,
#'   `"quarter"` or `"year"`, or `"all"` to collapse time completely (one value
#'   per group); `NULL` keeps the native frequency. Irregular timestamps
#'   (`kind = "time"`) must be given a `period`.
#' @param fun_time Summary applied *within each individual* when several
#'   periods collapse into one (default `"mean"`; use `"sum"` for flows).
#' @param fun_group Summary applied *across individuals* in a group
#'   (default `"mean"`). A name (`mean`, `median`, `sum`, `sd`, `min`, `max`,
#'   `first`, `last`, `n`, `share`, `p90`, ...) or a function.
#' @param min_n Drop group-periods with fewer than this many individuals
#'   (a privacy / noise threshold).
#' @return A tibble with `.period`, the `by` columns, the `vars`, and `.n`
#'   (individuals contributing).
#' @examples
#' d <- data.frame(who = rep(1:6, each = 4), yr = rep(2001:2004, 6),
#'                 grp = rep(c("x", "y"), each = 12), y = seq_len(24))
#' p <- as_panel(d, who, yr)
#' panel_aggregate(p, "y", by = "grp")
#' @export
panel_aggregate <- function(x, vars = NULL, by = NULL, period = NULL,
                            fun_time = "mean", fun_group = "mean", min_n = NULL) {
  m <- panel_meta(x)
  vars <- vars %||% panel_numeric_vars(x)
  vars <- setdiff(vars, c(by, ".id", ".time"))
  bad <- setdiff(c(vars, by), names(x))
  if (length(bad)) cli::cli_abort("Unknown column{?s}: {.field {bad}}.")
  nonnum <- vars[!vapply(x[vars], is.numeric, logical(1))]
  if (length(nonnum)) cli::cli_abort("Not numeric: {.field {nonnum}}.")
  if (length(vars) == 0) cli::cli_abort("No numeric columns to aggregate.")

  labels <- stats::setNames(lapply(vars, function(v) attr(x[[v]], "label")), vars)
  d <- tibble::as_tibble(unclass_panel(x))
  for (v in vars) d[[v]] <- strip_labels_col(d[[v]])
  for (v in setdiff(by, ".id")) d[[v]] <- label_col(d[[v]])
  # a missing group value is shown as its own group instead of vanishing silently
  for (v in setdiff(by, ".id")) if (anyNA(d[[v]])) d[[v]] <- ifelse(is.na(d[[v]]), "(missing)", as.character(d[[v]]))
  freq_out <- m$freq

  if (identical(period, "all")) {
    freq_out <- "all"; d$.period <- rep(min(d$.time), nrow(d))
  } else if (m$kind == "index") {
    if (!is.null(period)) cli::cli_abort("{.arg period} needs a dated time column; this panel's time is a plain index.")
    d$.period <- d$.time
  } else {
    if (!is.null(period)) {
      if (!period %in% names(freq_rank)) cli::cli_abort("{.arg period} must be one of {.val {names(freq_rank)}}.")
      if (m$freq %in% names(freq_rank) && freq_rank[[period]] < freq_rank[[m$freq]])
        cli::cli_abort("{.arg period} {.val {period}} is finer than the panel's {m$freq} frequency.")
      freq_out <- period
      d$.period <- if (m$freq == period) d$.time else floor_period(d$.time, period)
    } else if (m$freq == "irregular" || m$kind == "time") {
      cli::cli_abort("Timestamps are irregular; choose a {.arg period} such as {.val hour}, {.val day} or {.val week}.")
    } else d$.period <- d$.time
  }

  ft <- agg_fun(fun_time); fg <- agg_fun(fun_group)
  keep <- unique(c(".id", by))

  stage1 <- d |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(keep, ".period")))) |>
    dplyr::summarise(dplyr::across(dplyr::all_of(vars), ft), .groups = "drop")

  out <- stage1 |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(by, ".period")))) |>
    dplyr::summarise(.n = dplyr::n_distinct(.data$.id),
                     dplyr::across(dplyr::all_of(vars), fg), .groups = "drop")
  out <- out[c(".period", by, vars, ".n")]
  if (!is.null(min_n)) out <- out[out$.n >= min_n, ]
  out <- out[do.call(order, unname(as.list(out[c(by, ".period")]))), ]
  attr(out, "panel_info") <- list(kind = if (m$kind == "index") "index" else freq_out, freq = freq_out,
                                  n_ids = m$n_ids, freq_native = m$freq, source = m$source, labels = labels, min_n = min_n,
                                  range = if (nrow(out) && freq_out != "all") range(out$.period) else m$range)
  out
}

unclass_panel <- function(x) { attr(x, "panel") <- NULL; class(x) <- setdiff(class(x), "tidy_panel"); x }
label_col <- function(z) {
  if (inherits(z, "haven_labelled") && requireNamespace("haven", quietly = TRUE)) as.character(haven::as_factor(z)) else
    if (inherits(z, "haven_labelled")) as.vector(unclass(z)) else z
}
strip_labels_col <- function(z) if (inherits(z, "haven_labelled")) as.vector(unclass(z)) else z
`%||%` <- function(a, b) if (is.null(a)) b else a
