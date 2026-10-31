# Individual trajectories with the group average on top

Individual trajectories with the group average on top

## Usage

``` r
panel_spaghetti(
  x,
  var,
  by = NULL,
  period = NULL,
  fun_time = "mean",
  fun_group = "mean",
  n_ids = 100,
  seed = 1,
  log = FALSE,
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

- n_ids:

  Draw at most this many individual lines (random, reproducible).

- seed:

  Seed for the individual sample.

- log:

  Use a log10 value axis (helps when individuals differ in scale).

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
