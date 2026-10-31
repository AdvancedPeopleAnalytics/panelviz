# Stacked bars: how several measures add up within each group

Stacked bars: how several measures add up within each group

## Usage

``` r
panel_stacked(
  x,
  vars,
  by,
  period = "all",
  fun_time = "mean",
  fun_group = "mean",
  min_n = NULL,
  top_n = 15,
  min_label = 0.05,
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

- vars:

  Two or more numeric columns that form the stack.

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

- top_n:

  Keep this many groups.

- min_label:

  Hide a segment's value label when it is thinner than this share of the
  longest bar (avoids overflowing labels).

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
