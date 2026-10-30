#' Declare a data frame as a panel
#'
#' Tell panelviz which column(s) identify the individual and which column is
#' time. The time format is detected automatically (Date, POSIXct, years,
#' two-digit years, `"1998 Q1"`, `"2020-03"`, ISO weeks, `"3/14/2021"`,
#' `yyyymm`, `yyyymmdd`, Stata `%tm`/`%tq`/`%ty` values, plain integers).
#'
#' @param data A data frame in long format (one row per individual and time).
#' @param id Column(s) identifying the individual (a subject, unit, entity, participant, firm or
#'   country in other fields). Several columns are combined
#'   into one composite key. Unquoted names or strings.
#' @param time The time column (a wave, occasion, visit, period or year in other fields).
#' @param time_format `NULL` (auto-detect), a [strptime()] string, or one of
#'   `"year"`, `"quarter"`, `"month"`, `"week"`, `"index"`.
#' @param dups What to do when an individual has several rows at the same time:
#'   `"error"` (default) or `"keep"`.
#' @param source Where the data comes from, e.g. `"BLS; company reports"`. Shown as
#'   "Source: ..." in every chart footer.
#' @return A `tidy_panel`: the data plus standardised `.id` and `.time`
#'   columns, with the panel structure stored in `attr(, "panel")`.
#' @examples
#' d <- data.frame(who = rep(c("a", "b"), each = 4),
#'                 when = rep(c("2020 Q1", "2020 Q2", "2020 Q3", "2020 Q4"), 2),
#'                 y = c(1, 2, 3, 4, 2, 3, 5, 8))
#' as_panel(d, id = who, time = when)
#' @export
as_panel <- function(data, id, time, time_format = NULL, dups = c("error", "keep"), source = NULL) {
  dups <- match.arg(dups)
  data <- tibble::as_tibble(data)
  if (nrow(data) == 0) cli::cli_abort("{.arg data} must contain at least one row.")
  id_pos <- tidyselect::eval_select(rlang::enquo(id), data)
  time_pos <- tidyselect::eval_select(rlang::enquo(time), data)
  if (length(time_pos) != 1) cli::cli_abort("{.arg time} must select exactly one column.")
  if (length(id_pos) < 1) cli::cli_abort("{.arg id} must select at least one column.")
  id_cols <- names(id_pos); time_col <- names(time_pos)

  if (any(c(".id", ".time") %in% names(data)))
    cli::cli_abort("Columns named {.field .id} or {.field .time} already exist; rename them first.")

  ids <- lapply(data[id_cols], function(z) as.character(plain_id(z)))
  missing_id <- Reduce(`|`, lapply(ids, is.na))
  if (any(missing_id)) cli::cli_abort("{sum(missing_id)} row{?s} ha{?s/ve} a missing id.")
  key <- if (length(ids) == 1) ids[[1]] else
    do.call(paste, c(lapply(ids, function(z) {
      z <- gsub("\\", "\\\\", z, fixed = TRUE)
      gsub("|", "\\|", z, fixed = TRUE)
    }), sep = " | "))

  if (anyNA(data[[time_col]])) cli::cli_abort("{sum(is.na(data[[time_col]]))} row{?s} ha{?s/ve} a missing time value.")
  tm <- parse_time(data[[time_col]], time_format)
  if (anyNA(tm$value)) cli::cli_abort("{sum(is.na(tm$value))} row{?s} ha{?s/ve} a missing time value.")

  out <- dplyr::bind_cols(tibble::tibble(.id = key, .time = tm$value), data)
  freq <- infer_freq(tm$value, tm$kind)

  n_dup <- sum(duplicated(out[c(".id", ".time")]))
  if (n_dup > 0 && dups == "error")
    cli::cli_abort(c("{n_dup} row{?s} repeat an existing id and time.",
                     i = "The id may need more columns (e.g. {.code id = c(region, product)}), or use {.code dups = \"keep\"}."))

  out <- out[order(out$.id, out$.time), ]
  n_ids <- length(unique(out$.id)); n_per <- length(unique(out$.time))
  meta <- list(id = id_cols, time = time_col, kind = tm$kind, freq = freq,
               n_ids = n_ids, n_periods = n_per, n_obs = nrow(out),
               range = range(out$.time), balanced = n_dup == 0 && nrow(out) == n_ids * n_per,
               dups = n_dup, source = source)
  structure(out, panel = meta, class = c("tidy_panel", class(out)))
}

plain_id <- function(x) {
  if (inherits(x, "haven_labelled") && requireNamespace("haven", quietly = TRUE))
    return(haven::as_factor(x))
  x
}

#' @export
print.tidy_panel <- function(x, ...) {
  m <- attr(x, "panel")
  if (!is.null(m)) {
    rng <- if (m$kind == "index") paste(m$range, collapse = " to ") else
      paste(format(m$range), collapse = " to ")
    cat(sprintf("# A tidy panel: %s individuals x %s periods (%s), %s\n",
                format(m$n_ids, big.mark = ","), format(m$n_periods, big.mark = ","), m$freq, rng))
    cat(sprintf("# id = %s | time = %s | %s | %s obs\n", paste(m$id, collapse = " + "), m$time,
                if (m$balanced) "balanced" else sprintf("unbalanced (%.0f%% of id-period cells filled)",
                                                         100 * m$n_obs / (m$n_ids * m$n_periods)),
                format(m$n_obs, big.mark = ",")))
  }
  NextMethod()
}

#' Panel structure metadata
#' @param x A `tidy_panel`.
#' @return A list: id and time columns, time kind and frequency, counts, range,
#'   whether the panel is balanced.
#' @export
panel_meta <- function(x) {
  m <- attr(x, "panel")
  if (is.null(m)) cli::cli_abort("{.arg x} is not a tidy_panel; use {.fn as_panel} first.")
  m
}

#' Numeric columns that can be aggregated
#' @noRd
panel_numeric_vars <- function(x) {
  skip <- c(".id", ".time")
  v <- names(x)[vapply(x, is.numeric, logical(1))]
  setdiff(v, skip)
}
