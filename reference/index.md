# Package index

## Declare and import panels

Say which column is the individual and which is time, or read a file or
URL straight into a panel.

- [`as_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel.md)
  : Declare a data frame as a panel
- [`as_panel_wide()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel_wide.md)
  : Declare a wide-format data frame as a panel
- [`read_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/read_panel.md)
  : Read a panel from a file or URL
- [`panel_meta()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_meta.md)
  : Panel structure metadata

## Aggregate

Aggregate within individuals over time, then across individuals by
group, with an optional group-size floor.

- [`panel_aggregate()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_aggregate.md)
  : Aggregate a panel over time and across individuals

## Charts

One chart per question. All chart functions share the same arguments for
selecting groups, periods, aggregation and style.

- [`panel_plot()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_plot.md)
  : Plot a panel with a chosen chart type
- [`panel_line()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_line.md)
  : Line chart of a panel variable over time
- [`panel_heatmap()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_heatmap.md)
  : Heatmap of groups (rows) by time (columns)
- [`panel_spaghetti()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_spaghetti.md)
  : Individual trajectories with the group average on top
- [`panel_tracking()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_tracking.md)
  : Tracking chart: the period average with a rolling average
- [`panel_band()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_band.md)
  : Median with an inter-quantile band across individuals
- [`panel_bar()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_bar.md)
  : Ranked bars of groups
- [`panel_stacked()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_stacked.md)
  : Stacked bars: how several measures add up within each group
- [`panel_distribution()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_distribution.md)
  : Distribution of individuals

## Compose and save

- [`panel_figure()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_figure.md)
  : Compose several charts into one numbered figure
- [`save_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/save_panel.md)
  : Save a chart or figure

## Style

Five looks, set globally or per chart, plus the theme and font hooks
behind them.

- [`panel_styles()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_styles.md)
  : Available looks
- [`use_panel_style()`](https://advancedpeopleanalytics.github.io/panelviz/reference/use_panel_style.md)
  : Set the look for the session
- [`theme_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/theme_panel.md)
  : Theme for panel graphics
- [`panel_font()`](https://advancedpeopleanalytics.github.io/panelviz/reference/panel_font.md)
  : Best available condensed font

## Package

- [`panelviz`](https://advancedpeopleanalytics.github.io/panelviz/reference/panelviz-package.md)
  [`panelviz-package`](https://advancedpeopleanalytics.github.io/panelviz/reference/panelviz-package.md)
  : panelviz: Import, Aggregate and Visualise Any Panel Data
