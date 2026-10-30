---
name: panelviz
description: Chart panel (longitudinal) data with the panelviz R package. Use when the user has data with an individual/ID column and a time column (CSV, Excel, Stata, SPSS, data frame) and wants publication-ready line, heatmap, spaghetti, band, bar, stacked or distribution charts, or a multi-chart figure, saved as PNG/PDF/SVG.
---

# panelviz as a chart engine

panelviz turns "which column is the individual, which is time" into finished charts. Run it through `Rscript`, save the image to a file, then look at the file.

## 1. Make sure it is installed

```bash
Rscript -e 'if (!requireNamespace("panelviz", quietly = TRUE)) pak::pak("AdvancedPeopleAnalytics/panelviz")'
```

## 2. Pattern

```bash
Rscript -e '
library(panelviz)
x <- read_panel("data.csv", id = person_id, time = year)   # or as_panel(df, id =, time =)
p <- panel_plot(x, "income", kind = "line", by = region)    # see kinds below
save_panel(p, "chart.png", width = 9, height = 5)
'
```

`id` and `time` are unquoted column names (tidyselect). `read_panel()` reads csv, xlsx, dta, sav and URLs; use `time_format =` if dates do not parse, and `dups = "keep"` if an individual has several rows per period.

## 3. Choosing a chart

`panel_plot(x, var, kind = ...)` dispatches to the `panel_*` functions:

| kind | use for |
|---|---|
| `line` | group averages over time (`by =`, `period =`, `facet =`, `highlight =`, `index = TRUE` to rebase) |
| `spaghetti` | every individual's path |
| `band` | spread (range/quantiles) around a central line |
| `heatmap` | individuals x time at a glance |
| `tracking` | follow selected individuals |
| `bar`, `stacked` | composition or comparison by period |
| `distribution` | how values are spread per period |

Aggregation is built in: `by` groups individuals, `period` coarsens time (`"month"`, `"year"`...), `fun_time` summarises within an individual, `fun_group` across individuals. `return = "table"` gives the plotted numbers instead of the chart.

For several charts on one page: `panel_figure(list(p1, p2), ncol = 2, title =, subtitle =, source =, notes =)`, then `save_panel()`.

Titles and axes are computed from the data. Override with `title =`/`subtitle =`. Look is set by `use_panel_style()`; `panel_styles()` lists the options.

## 4. Always

- Check `panel_meta(x)` or `print(x)` first when the user is unsure of the structure.
- Save to a file and open or read the image to confirm it before reporting. Do not describe a chart you have not looked at.
- Pass `source =` so the footer cites the data.
- If `as_panel()` errors on duplicates, report it and ask whether to aggregate or keep them. Do not silently drop rows.
- Function help: `Rscript -e 'help(panel_line, package="panelviz")'`.
