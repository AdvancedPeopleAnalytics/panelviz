# Plot a panel with a chosen chart type

Plot a panel with a chosen chart type

## Usage

``` r
panel_plot(
  x,
  var,
  kind = c("line", "heatmap", "spaghetti", "tracking", "band", "bar", "stacked",
    "distribution"),
  ...
)
```

## Arguments

- x:

  A `tidy_panel`.

- var:

  The variable to plot.

- kind:

  One of `"line"`, `"heatmap"`, `"spaghetti"`, `"tracking"`, `"band"`,
  `"bar"`, `"stacked"`, `"distribution"`. For `"stacked"`, `var` is a
  vector of columns.

- ...:

  Passed to the chart function.
