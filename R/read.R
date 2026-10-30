#' Read a panel from a file or URL
#'
#' Reads CSV/TSV, Stata `.dta`, SPSS `.sav` or `.rds` (local path or URL) and
#' declares it a panel with [as_panel()].
#'
#' @param path File path or URL.
#' @inheritParams as_panel
#' @param ... Passed to the underlying reader.
#' @return A `tidy_panel`.
#' @export
read_panel <- function(path, id, time, time_format = NULL, dups = c("error", "keep"), ...) {
  dups <- match.arg(dups)
  ext <- tolower(tools::file_ext(sub("[?#].*$", "", path)))
  need <- function(pkg) if (!requireNamespace(pkg, quietly = TRUE))
    cli::cli_abort("Reading {.val .{ext}} files needs the {.pkg {pkg}} package.")
  data <- switch(ext,
    csv = , txt = { need("readr"); readr::read_csv(path, show_col_types = FALSE, ...) },
    tsv = { need("readr"); readr::read_tsv(path, show_col_types = FALSE, ...) },
    dta = { need("haven"); haven::read_dta(path, ...) },
    sav = { need("haven"); haven::read_sav(path, ...) },
    rds = readRDS(path),
    cli::cli_abort("Unsupported file type {.val .{ext}}."))
  as_panel(data, id = {{ id }}, time = {{ time }}, time_format = time_format, dups = dups)
}
