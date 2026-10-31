# Theme for panel graphics

Theme for panel graphics

## Usage

``` r
theme_panel(
  font_size = 12,
  base_family = panel_font(),
  style = getOption("panelviz.style", "economist")
)
```

## Arguments

- font_size:

  Base size.

- base_family:

  Font family; defaults to
  [`panel_font()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_font.md).

- style:

  One of
  [`panel_styles()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_styles.md);
  default `"economist"` (or `options(panelviz.style = )`).
