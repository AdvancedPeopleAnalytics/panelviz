# Time parsing: turn whatever the user's time column looks like into a
# `.time` column (Date, or numeric for plain indices) plus a `kind`.

time_kinds <- c("time", "hour", "day", "week", "month", "quarter", "year", "index")

#' Parse a time column
#'
#' @param x A vector holding the time information.
#' @param format `NULL` to auto-detect, a `strptime()` format string, or one of
#'   `"year"`, `"quarter"`, `"month"`, `"week"`, `"index"`.
#' @return A list with `value` (Date, or numeric for `"index"`) and `kind`.
#' @keywords internal
#' @noRd
parse_time <- function(x, format = NULL) {
  stata <- attr(x, "format.stata")
  x <- strip_labels(x)

  if (is.null(format) && !is.null(stata) && is.numeric(x)) {
    out <- parse_stata_time(x, stata)
    if (!is.null(out)) return(out)
  }
  if (inherits(x, "POSIXt")) return(finish_datetime(x))
  if (inherits(x, "Date")) return(list(value = x, kind = "date"))
  if (is.factor(x)) x <- as.character(x)

  u <- unique(x)
  res <- if (!is.null(format)) parse_time_format(u, format) else
    if (is.numeric(u)) parse_time_numeric(u) else parse_time_character(u)
  list(value = res$value[match(x, u)], kind = res$kind)
}

# Keep the clock face of a timestamp (UTC), and fall back to plain dates when
# every timestamp is midnight.
finish_datetime <- function(x) {
  x <- as.POSIXct(format(x, "%Y-%m-%d %H:%M:%S"), tz = "UTC")
  secs <- as.numeric(x) %% 86400
  v <- secs[!is.na(secs)]
  if (all(v == 0)) return(list(value = as.Date(x), kind = "date"))
  list(value = x, kind = if (all(v %% 3600 == 0)) "hour" else "time")
}

strip_labels <- function(x) {
  if (inherits(x, "haven_labelled")) {
    f <- attr(x, "format.stata")
    x <- unclass(x)
    attributes(x) <- NULL
    if (!is.null(f)) attr(x, "format.stata") <- f
  }
  x
}

stata_epoch_month <- function(n) {
  as.Date(sprintf("%04d-%02d-01", 1960L + n %/% 12L, n %% 12L + 1L))
}

parse_stata_time <- function(x, fmt) {
  fmt <- sub("^%", "", fmt)
  if (grepl("^tm", fmt)) return(list(value = stata_epoch_month(as.integer(x)), kind = "month"))
  if (grepl("^tq", fmt)) return(list(value = stata_epoch_month(as.integer(x) * 3L), kind = "quarter"))
  if (grepl("^th", fmt)) return(list(value = stata_epoch_month(as.integer(x) * 6L), kind = "quarter"))
  if (grepl("^ty", fmt)) return(list(value = year_start(x), kind = "year"))
  if (grepl("^tw", fmt)) {
    n <- as.integer(x)
    return(list(value = as.Date(sprintf("%04d-01-01", 1960L + n %/% 52L)) + (n %% 52L) * 7L, kind = "week"))
  }
  NULL
}

year_start <- function(y) as.Date(sprintf("%04d-01-01", as.integer(y)))

parse_time_numeric <- function(u) {
  v <- u[!is.na(u)]
  whole <- all(v == round(v))
  if (whole && length(v) > 0) {
    if (all(v >= 1000 & v <= 2999)) return(list(value = year_start(u), kind = "year"))
    if (all(v >= 30 & v <= 99)) {
      cli::cli_inform("Reading values {min(v)}-{max(v)} as two-digit years (19xx); pass {.code time_format = \"index\"} to keep them as plain numbers.")
      return(list(value = year_start(1900 + u), kind = "year"))
    }
    if (all(v >= 190001 & v <= 209912 & v %% 100 %in% 1:12))
      return(list(value = as.Date(sprintf("%04d-%02d-01", as.integer(u %/% 100), as.integer(u %% 100))), kind = "month"))
    if (all(v >= 19000101 & v <= 20991231)) {
      d <- as.Date(as.character(u), "%Y%m%d")
      if (!anyNA(d[!is.na(u)])) return(list(value = d, kind = "date"))
    }
  }
  list(value = as.numeric(u), kind = "index")
}

week_start <- function(year, week) {
  jan4 <- as.Date(sprintf("%04d-01-04", as.integer(year)))
  monday <- jan4 - (as.integer(format(jan4, "%u")) - 1L)
  monday + (as.integer(week) - 1L) * 7L
}

parse_time_character <- function(u) {
  v <- trimws(u[!is.na(u)])
  all_match <- function(rx) length(v) > 0 && all(grepl(rx, v))

  if (all_match("^\\S+[ T]\\d{1,2}:\\d{2}")) {
    for (f in c("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M",
                "%m/%d/%Y %H:%M:%S", "%m/%d/%Y %H:%M", "%d/%m/%Y %H:%M:%S", "%d/%m/%Y %H:%M")) {
      d <- as.POSIXct(u, format = f, tz = "UTC")
      if (!anyNA(d[!is.na(u)])) return(finish_datetime(d))
    }
  }
  # numbers stored as text (e.g. wide-format column names such as "2001" or "80")
  if (all_match("^\\d+$")) return(parse_time_numeric(as.numeric(u)))
  rx_q <- "^\\d{4}\\s*[- ]?\\s*[Qq][1-4]$"
  if (all_match(rx_q)) {
    yr <- as.integer(substr(trimws(u), 1, 4)); q <- as.integer(sub(".*[Qq]", "", u))
    return(list(value = as.Date(sprintf("%04d-%02d-01", yr, 3L * q - 2L)), kind = "quarter"))
  }
  rx_w <- "^\\d{4}\\s*[- ]?\\s*[Ww]\\d{1,2}$"
  if (all_match(rx_w)) {
    yr <- as.integer(substr(trimws(u), 1, 4)); w <- as.integer(sub(".*[Ww]", "", u))
    return(list(value = week_start(yr, w), kind = "week"))
  }
  if (all_match("^\\d{4}$")) return(list(value = year_start(u), kind = "year"))
  if (all_match("^\\d{4}[-/]\\d{1,2}$")) {
    d <- as.Date(paste0(gsub("/", "-", trimws(u)), "-01"), "%Y-%m-%d")
    return(list(value = d, kind = "month"))
  }
  for (f in c("%Y %b", "%b %Y", "%B %Y", "%b-%y", "%b-%Y", "%Y-%b")) {
    d <- as.Date(paste0("01 ", trimws(u)), paste0("%d ", f))
    if (length(v) > 0 && !anyNA(d[!is.na(u)])) return(list(value = d, kind = "month"))
  }

  candidates <- c("%Y-%m-%d", "%Y/%m/%d", "%m/%d/%Y", "%d/%m/%Y", "%d-%m-%Y",
                  "%m-%d-%Y", "%d.%m.%Y", "%d %b %Y", "%b %d, %Y", "%d%b%Y", "%Y%m%d",
                  "%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S")
  ok <- list()
  for (f in candidates) {
    d <- as.Date(u, f)
    if (length(v) > 0 && !anyNA(d[!is.na(u)])) ok[[f]] <- d
  }
  if (length(ok) == 0)
    cli::cli_abort(c("Could not recognise the time format.",
                     i = "Examples seen: {.val {utils::head(v, 3)}}",
                     i = "Pass {.arg time_format} as a {.fn strptime} string, e.g. {.code \"%d.%m.%Y\"}."))
  distinct <- unique(lapply(ok, as.numeric))
  if (length(distinct) > 1)
    cli::cli_abort(c("The time format is ambiguous: {.val {names(ok)}} all parse.",
                     i = "Pass {.arg time_format} to choose, e.g. {.code time_format = \"{names(ok)[1]}\"}."))
  list(value = ok[[1]], kind = "date")
}

parse_time_format <- function(u, format) {
  if (format == "index") return(list(value = as.numeric(u), kind = "index"))
  if (format %in% c("year", "quarter", "month", "week")) {
    out <- if (is.numeric(u)) parse_time_numeric(u) else parse_time_character(u)
    out$kind <- if (out$kind == "date") "date" else out$kind
    return(out)
  }
  d <- as.Date(as.character(u), format)
  bad <- is.na(d) & !is.na(u)
  if (any(bad)) cli::cli_abort("{sum(bad)} value{?s} did not match {.code {format}}, e.g. {.val {utils::head(u[bad], 3)}}.")
  list(value = d, kind = "date")
}

#' Infer the frequency of a date vector
#' @noRd
infer_freq <- function(date, kind) {
  if (kind %in% c("year", "quarter", "month", "week", "index")) return(kind)
  d <- sort(unique(date[!is.na(date)]))
  if (kind %in% c("hour", "time")) {
    if (length(d) < 2) return(kind)
    m <- as.numeric(names(sort(table(as.numeric(diff(d), units = "secs")), decreasing = TRUE))[1])
    return(if (m == 3600) "hour" else if (m %% 3600 == 0 && m <= 3600) "hour" else "irregular")
  }
  if (length(d) < 2) return("day")
  gaps <- as.integer(diff(d))
  m <- as.integer(names(sort(table(gaps), decreasing = TRUE))[1])
  if (m <= 1) "day" else if (m <= 7) "week" else if (m <= 31) "month"
  else if (m <= 92) "quarter" else if (m <= 366) "year" else "irregular"
}

freq_rank <- c(hour = 0, day = 1, week = 2, month = 3, quarter = 4, year = 5)

#' Floor dates to the start of a period
#' @noRd
floor_period <- function(d, period) {
  if (inherits(d, "POSIXt")) {
    if (period == "hour") return(as.POSIXct(trunc(d, "hours")))
    d <- as.Date(d)
  }
  switch(period,
    day = d,
    week = d - (as.integer(format(d, "%u")) - 1L),
    month = as.Date(format(d, "%Y-%m-01")),
    quarter = as.Date(sprintf("%s-%02d-01", format(d, "%Y"), 3L * ((as.integer(format(d, "%m")) - 1L) %/% 3L) + 1L)),
    year = as.Date(format(d, "%Y-01-01")),
    cli::cli_abort("Unknown period {.val {period}}; use one of {.val {names(freq_rank)}}."))
}
