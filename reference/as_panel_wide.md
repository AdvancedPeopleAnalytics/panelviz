# Declare a wide-format data frame as a panel

Wide data has one column per period (`inc80`, `inc81`, ...) or one
column per period and measure. Those columns are pivoted to long format
and passed to
[`as_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel.md),
so the usual time-format detection applies to the column names.

## Usage

``` r
as_panel_wide(
  data,
  id,
  cols,
  names_pattern = NULL,
  values_to = "value",
  time_format = NULL,
  dups = c("error", "keep"),
  source = NULL
)
```

## Arguments

- data:

  A data frame with one row per individual.

- id:

  Column(s) identifying the individual.

- cols:

  The period columns (tidyselect: `starts_with("inc")`, `2001:2005`,
  ...).

- names_pattern:

  `NULL` when the column names *are* the periods (`"2001"`, `"2002"`).
  Otherwise a regular expression with two groups, measure then period,
  e.g. `"^(inc|ue)(\\d+)$"` for `inc80`, `ue81`.

- values_to:

  Name of the value column when `names_pattern` is `NULL`.

- time_format:

  `NULL` (auto-detect), a
  [`strptime()`](https://rdrr.io/r/base/strptime.html) string, or one of
  `"year"`, `"quarter"`, `"month"`, `"week"`, `"index"`.

- dups:

  What to do when an individual has several rows at the same time:
  `"error"` (default) or `"keep"`.

- source:

  Where the data comes from, e.g. `"BLS; company reports"`. Shown as
  "Source: ..." in every chart footer.

## Value

A `tidy_panel` whose time column is called `period`.

## Examples

``` r
w <- data.frame(who = 1:3, `2001` = c(5, 6, 7), `2002` = c(6, 8, 9), check.names = FALSE)
as_panel_wide(w, who, cols = c(`2001`, `2002`), values_to = "income")
#> # A tidy panel: 3 individuals x 2 periods (year), 2001-01-01 to 2002-01-01
#> # id = who | time = period | balanced | 6 obs
#> # A tibble: 6 × 5
#>   .id   .time        who period income
#> * <chr> <date>     <int> <chr>   <dbl>
#> 1 1     2001-01-01     1 2001        5
#> 2 1     2002-01-01     1 2002        6
#> 3 2     2001-01-01     2 2001        6
#> 4 2     2002-01-01     2 2002        8
#> 5 3     2001-01-01     3 2001        7
#> 6 3     2002-01-01     3 2002        9
```
