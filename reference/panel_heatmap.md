# Heatmap of groups (rows) by time (columns)

Heatmap of groups (rows) by time (columns)

## Usage

``` r
panel_heatmap(
  x,
  var,
  by = NULL,
  period = NULL,
  fun_time = "mean",
  fun_group = "mean",
  min_n = NULL,
  max_rows = 40,
  diverge = FALSE,
  palette = NULL,
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

- fun_group:

  Summary applied *across individuals* in a group (default `"mean"`). A
  name (`mean`, `median`, `sum`, `sd`, `min`, `max`, `first`, `last`,
  `n`, `share`, `p90`, ...) or a function.

- min_n:

  Drop group-periods with fewer than this many individuals (a privacy /
  noise threshold).

- max_rows:

  When `by` is `NULL` rows are individuals; show this many (evenly
  spaced after sorting by level).

- diverge:

  Use a diverging blue-white-red scale centred on the overall mean.

- palette:

  Vector of colours for the sequential scale.

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
