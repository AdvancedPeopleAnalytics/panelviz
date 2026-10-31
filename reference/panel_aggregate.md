# Aggregate a panel over time and across individuals

Aggregate a panel over time and across individuals

## Usage

``` r
panel_aggregate(
  x,
  vars = NULL,
  by = NULL,
  period = NULL,
  fun_time = "mean",
  fun_group = "mean",
  min_n = NULL
)
```

## Arguments

- x:

  A `tidy_panel` from
  [`as_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel.md).

- vars:

  Numeric columns to summarise; default all numeric columns.

- by:

  Grouping column(s) to aggregate individuals into (e.g. a region);
  `NULL` for one overall series. Use `".id"` to keep individuals.

- period:

  Coarsen time to `"hour"`, `"day"`, `"week"`, `"month"`, `"quarter"` or
  `"year"`, or `"all"` to collapse time completely (one value per
  group); `NULL` keeps the native frequency. Irregular timestamps
  (`kind = "time"`) must be given a `period`.

- fun_time:

  Summary applied *within each individual* when several periods collapse
  into one (default `"mean"`; use `"sum"` for flows).

- fun_group:

  Summary applied *across individuals* in a group (default `"mean"`). A
  name (`mean`, `median`, `sum`, `sd`, `min`, `max`, `first`, `last`,
  `n`, `share`, `p90`, ...) or a function.

- min_n:

  Drop group-periods with fewer than this many individuals (a privacy /
  noise threshold).

## Value

A tibble with `.period`, the `by` columns, the `vars`, and `.n`
(individuals contributing).

## Examples

``` r
d <- data.frame(who = rep(1:6, each = 4), yr = rep(2001:2004, 6),
                grp = rep(c("x", "y"), each = 12), y = seq_len(24))
p <- as_panel(d, who, yr)
panel_aggregate(p, "y", by = "grp")
#> # A tibble: 8 × 4
#>   .period    grp       y    .n
#>   <date>     <chr> <dbl> <int>
#> 1 2001-01-01 x         5     3
#> 2 2002-01-01 x         6     3
#> 3 2003-01-01 x         7     3
#> 4 2004-01-01 x         8     3
#> 5 2001-01-01 y        17     3
#> 6 2002-01-01 y        18     3
#> 7 2003-01-01 y        19     3
#> 8 2004-01-01 y        20     3
```
