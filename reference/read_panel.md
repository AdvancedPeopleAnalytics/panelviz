# Read a panel from a file or URL

Reads CSV/TSV, Stata `.dta`, SPSS `.sav` or `.rds` (local path or URL)
and declares it a panel with
[`as_panel()`](https://advancedpeopleanalytics.github.io/panelviz/reference/as_panel.md).

## Usage

``` r
read_panel(
  path,
  id,
  time,
  time_format = NULL,
  dups = c("error", "keep"),
  source = basename(path),
  ...
)
```

## Arguments

- path:

  File path or URL.

- id:

  Column(s) identifying the individual (a subject, unit, entity,
  participant, firm or country in other fields). Several columns are
  combined into one composite key. Unquoted names or strings.

- time:

  The time column (a wave, occasion, visit, period or year in other
  fields).

- time_format:

  `NULL` (auto-detect), a
  [`strptime()`](https://rdrr.io/r/base/strptime.html) string, or one of
  `"year"`, `"quarter"`, `"month"`, `"week"`, `"index"`.

- dups:

  What to do when an individual has several rows at the same time:
  `"error"` (default) or `"keep"`.

- source:

  Source line for chart footers; defaults to the file name.

- ...:

  Passed to the underlying reader.

## Value

A `tidy_panel`.
