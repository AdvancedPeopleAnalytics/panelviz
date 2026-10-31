# Save a chart or figure

Works for any `panel_*` chart and for
[`panel_figure()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_figure.md).
Uses `ragg` when installed for the best font rendering.

## Usage

``` r
save_panel(x, file, width = 9, height = 5, dpi = 150)
```

## Arguments

- x:

  A chart or figure.

- file:

  Path ending in `.png`, `.pdf` or `.svg`.

- width, height:

  Size in inches.

- dpi:

  Resolution for PNG.

## Value

`file`, invisibly.
