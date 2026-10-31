# Median with an inter-quantile band across individuals

Shows the spread of individuals, not just the average.

## Usage

``` r
panel_band(
  x,
  var,
  by = NULL,
  period = NULL,
  fun_time = "mean",
  lower = "p25",
  upper = "p75",
  centre = "median",
  min_n = NULL,
  max_groups = 6,
  tag = NULL,
  source = NULL,
  style = NULL,
  return = c("plot", "table"),
  title = NULL,
  subtitle = NULL
)
```

## Arguments

- x:

  A `tidy_panel`.

- var:

  The variable to plot.

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

- lower, upper:

  Band edges as percentile names (`"p25"`, `"p75"`, `"p10"`, `"p90"`).

- centre:

  Centre line summary (default `"median"`).

- min_n:

  Drop group-periods with fewer than this many individuals (a privacy /
  noise threshold).

- max_groups:

  Keep only this many groups (largest by individuals).

- tag:

  Optional figure number or label, drawn in a square at the top right.

- source:

  Source line for the footer; default is the source given to
  [`as_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel.md).

- style:

  Look for this chart: one of
  [`panel_styles()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_styles.md).

- return:

  `"plot"` or `"table"`.

- title, subtitle:

  Optional text; defaults are generated.
