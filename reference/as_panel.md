# Declare a data frame as a panel

Tell panelviz which column(s) identify the individual and which column
is time. The time format is detected automatically (Date, POSIXct,
years, two-digit years, `"1998 Q1"`, `"2020-03"`, ISO weeks,
`"3/14/2021"`, `yyyymm`, `yyyymmdd`, Stata `%tm`/`%tq`/`%ty` values,
plain integers).

## Usage

``` r
as_panel(
  data,
  id,
  time,
  time_format = NULL,
  dups = c("error", "keep"),
  source = NULL
)
```

## Arguments

- data:

  A data frame in long format (one row per individual and time).

- id:

  Column(s) identifying the individual (a subject, unit, entity,
  participant, firm or country in other fields). Several columns are
  combined into one composite key. Unquoted names or strings.

- time:

  The time column (a wave, occasion, visit, period or year in other
  fields).

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

A `tidy_panel`: the data plus standardised `.id` and `.time` columns,
with the panel structure stored in `attr(, "panel")`.

## Examples

``` r
d <- data.frame(who = rep(c("a", "b"), each = 4),
                when = rep(c("2020 Q1", "2020 Q2", "2020 Q3", "2020 Q4"), 2),
                y = c(1, 2, 3, 4, 2, 3, 5, 8))
as_panel(d, id = who, time = when)
#> # A tidy panel: 2 individuals x 4 periods (quarter), 2020-01-01 to 2020-10-01
#> # id = who | time = when | balanced | 8 obs
#> # A tibble: 8 × 5
#>   .id   .time      who   when        y
#> * <chr> <date>     <chr> <chr>   <dbl>
#> 1 a     2020-01-01 a     2020 Q1     1
#> 2 a     2020-04-01 a     2020 Q2     2
#> 3 a     2020-07-01 a     2020 Q3     3
#> 4 a     2020-10-01 a     2020 Q4     4
#> 5 b     2020-01-01 b     2020 Q1     2
#> 6 b     2020-04-01 b     2020 Q2     3
#> 7 b     2020-07-01 b     2020 Q3     5
#> 8 b     2020-10-01 b     2020 Q4     8
```
