# panelviz 1.0.0

First release.

Release preparation:

* Reject empty panels and missing composite identifiers, and keep composite identifiers distinct when their values contain separators.
* Support `period = "all"` for panels with plain numeric time indices.
* Place line labels at each group's last observed value, including when other groups have missing values.
* Preserve the caller's random-number state when sampling individual trajectories.
* Validate figure dimensions and use supported PDF and PostScript fonts before drawing.
* Wrap figure headlines and subtitles to the available column width and reserve space for numbered tags.
* Keep direct line labels inside the panel by measuring the drawn label positions and widening the x-axis expansion to fit them.
* Lay out figure legend keys in compact rows and shrink type so cells keep a readable plot area.
* Add a getting-started vignette (`vignette("getting-started", "panelviz")`) covering the full workflow on simulated data.

* Declare a panel with `as_panel()`, `as_panel_wide()` or `read_panel()` (csv, tsv, Stata, SPSS, rds; path or URL): say which column is the individual and which is time.
* Time formats are detected: dates, hourly timestamps, years, two-digit years, quarters, months, ISO weeks, `yyyymm`, text dates, Stata `%tm/%tq/%ty` and plain indices. Ambiguous dates and repeated id-time rows stop with a message.
* `panel_aggregate()` aggregates in two stages, within individual over time (`fun_time`) and across individuals into groups (`fun_group`), with `min_n` as a privacy floor.
* Charts: `panel_line()`, `panel_heatmap()`, `panel_spaghetti()`, `panel_tracking()`, `panel_band()`, `panel_bar()`, `panel_stacked()`, `panel_distribution()`, and `panel_plot()` to choose by name. All share `by`, `period`, `fun_time`, `fun_group`, `min_n`, `tag`, `source`, `style` and `return = "table"`.
* Axes pick their own units and detect percentages; titles and subtitles are computed from the data and can be overridden.
* Five looks: `economist` (default), `ft`, `clean`, `dark` and `mono`, set with `use_panel_style()` or per chart with `style =`.
* `panel_figure()` composes numbered multi-panel figures with a shared source footer; `save_panel()` saves any chart.
* Charts fall back to the device's default font when it cannot use the preferred one.
