#' Declare a wide-format data frame as a panel
#'
#' Wide data has one column per period (`inc80`, `inc81`, ...) or one column per
#' period and measure. Those columns are pivoted to long format and passed to
#' [as_panel()], so the usual time-format detection applies to the column names.
#'
#' @param data A data frame with one row per individual.
#' @param id Column(s) identifying the individual.
#' @param cols The period columns (tidyselect: `starts_with("inc")`, `2001:2005`, ...).
#' @param names_pattern `NULL` when the column names *are* the periods
#'   (`"2001"`, `"2002"`). Otherwise a regular expression with two groups,
#'   measure then period, e.g. `"^(inc|ue)(\\d+)$"` for `inc80`, `ue81`.
#' @param values_to Name of the value column when `names_pattern` is `NULL`.
#' @inheritParams as_panel
#' @return A `tidy_panel` whose time column is called `period`.
#' @examples
#' w <- data.frame(who = 1:3, `2001` = c(5, 6, 7), `2002` = c(6, 8, 9), check.names = FALSE)
#' as_panel_wide(w, who, cols = c(`2001`, `2002`), values_to = "income")
#' @export
as_panel_wide <- function(data, id, cols, names_pattern = NULL, values_to = "value",
                          time_format = NULL, dups = c("error", "keep")) {
  dups <- match.arg(dups)
  data <- tibble::as_tibble(data)
  cols <- names(tidyselect::eval_select(rlang::enquo(cols), data))
  if (length(cols) == 0) cli::cli_abort("{.arg cols} selected no columns.")
  id_cols <- names(tidyselect::eval_select(rlang::enquo(id), data))
  long <- if (is.null(names_pattern)) {
    tidyr::pivot_longer(data, dplyr::all_of(cols), names_to = "period", values_to = values_to)
  } else {
    tidyr::pivot_longer(data, dplyr::all_of(cols), names_to = c(".value", "period"),
                        names_pattern = names_pattern)
  }
  as_panel(long, id = dplyr::all_of(id_cols), time = "period", time_format = time_format, dups = dups)
}
