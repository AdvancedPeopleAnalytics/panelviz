# Builds the Examples section of README.md. Every command shown is the command that was run to make
# the picture or the printed output next to it, so they cannot drift apart.
# Usage: Rscript data-raw/readme_examples.R   (needs internet; writes man/figures/ex_*.png)
suppressMessages({pkgload::load_all(".", quiet = TRUE)})
`%||%` <- function(a, b) if (is.null(a)) b else a
options(width = 100, cli.num_colors = 1, pillar.bold = FALSE, crayon.enabled = FALSE)
figdir <- "man/figures"

setup <- c(
'library(panelviz)',
'',
'# Stata dta, text csv and daily csv, straight from the web: id = who, time = when',
'nls   <- read_panel("https://www.stata-press.com/data/r18/nlswork.dta",',
'                    id = idcode, time = year, source = "US Bureau of Labor Statistics, NLS of Young Women")',
'gm    <- read_panel("https://raw.githubusercontent.com/plotly/datasets/master/gapminderDataFiveYear.csv",',
'                    id = country, time = year, source = "Gapminder")',
'tour  <- read_panel("https://vincentarelbundock.github.io/Rdatasets/csv/tsibble/tourism.csv",',
'                    id = c(Region, State, Purpose), time = Quarter, source = "Tourism Research Australia")',
'covid <- read_panel("https://raw.githubusercontent.com/datasets/covid-19/main/data/countries-aggregated.csv",',
'                    id = Country, time = Date, source = "Johns Hopkins CSSE")',
'gf    <- read_panel("https://www.stata-press.com/data/r18/grunfeld.dta",',
'                    id = company, time = year, source = "Grunfeld (1958)")')
eval(parse(text = setup))

# kind "text" prints output, kind "plot" draws a chart, kind "fig" draws a figure (14 x 9)
ex <- list(
 list(id = "declare", h = "Declare the panel", kind = "text",
  why = "Say which column is the individual and which is time. panelviz recognises the time format, sorts the data and reports its shape: 4,711 women observed in 15 survey years, unbalanced because not everyone answered every year.",
  args = c("`id`: one column, or several for a composite key (`c(Region, State, Purpose)`)", "`time`: the time column, in almost any format", "`source`: printed as \"Source: ...\" in every chart footer"),
  code = 'print(nls, n = 3)'),
 list(id = "formats", h = "Time formats are detected", kind = "text",
  why = "The same call handles quarters, ISO weeks, US-style dates, `yyyymm` numbers and hourly timestamps. Ambiguous input (`01/02/2020`) stops with a message instead of guessing; pass `time_format` to choose.",
  args = c("`time_format`: `NULL` (detect), a `strptime()` string such as `\"%d.%m.%Y\"`, or `\"year\"`, `\"quarter\"`, `\"month\"`, `\"week\"`, `\"index\"`"),
  code = 'what <- list(quarters = c("1998 Q1", "1998 Q2"), iso_weeks = c("2020-W01", "2020-W02"),
             us_dates = c("12/15/2019", "12/22/2019"), yyyymm = c(202001, 202002),
             hourly = c("2024-03-01 00:00:00", "2024-03-01 01:00:00"), two_digit_years = c(68, 69))
sapply(what, function(x) unlist(panel_meta(as_panel(data.frame(id = 1, t = x), id, t))[c("kind", "freq")]))'),
 list(id = "wide", h = "Wide data", kind = "text",
  why = "One column per period (and per measure) is pivoted to long format first. Here Stata's `reshape1` has `inc80 inc81 inc82` and `ue80 ue81 ue82`.",
  args = c("`cols`: the period columns (tidyselect)", "`names_pattern`: regular expression with two groups, measure then period; `NULL` when the column names are the periods"),
  code = 'wide <- as_panel_wide(haven::read_dta("https://www.stata-press.com/data/r18/reshape1.dta"),
                       id, cols = c(starts_with("inc"), starts_with("ue")),
                       names_pattern = "^(inc|ue)(\\\\d+)$")
wide'),
 list(id = "aggregate", h = "Aggregate in two stages", kind = "text",
  why = "Panel data has two dimensions, so aggregation has two stages. First, within each individual, time is collapsed into `period` (`fun_time`). Then individuals are collapsed into groups (`fun_group`). Here: each tourism flow's yearly *total* trips, then the *mean* across flows in each state. `.n` is the number of individuals behind each value.",
  args = c("`vars`: numeric columns to summarise (default all)", "`by`: grouping column(s); `NULL` for one overall series; `\".id\"` keeps individuals", "`period`: `\"hour\"`, `\"day\"`, `\"week\"`, `\"month\"`, `\"quarter\"`, `\"year\"` or `\"all\"`", "`fun_time`, `fun_group`: `mean median sum sd min max first last n share p10 p90 ...` or any function", "`min_n`: drop group-periods with fewer individuals"),
  code = 'panel_aggregate(tour, "Trips", by = "State", period = "year", fun_time = "sum", fun_group = "mean")'),
 list(id = "line", h = "Line: one overall series", kind = "plot", w = 9, h_in = 5,
  why = "The title is computed from the data. Axes use the best units, and the year appears only where it changes.",
  args = c("`var`: the variable to plot"), code = 'panel_line(nls, "ln_wage")'),
 list(id = "line_by", h = "Line: one line per group", kind = "plot",
  why = "Lines are labelled directly. When the leader changes, the headline says who overtook whom.",
  args = c("`by`: the grouping column", "`max_groups`: keep the largest groups (default 10)"),
  code = 'panel_line(gm, "lifeExp", by = "continent")'),
 list(id = "line_highlight", h = "Line: highlight one group, index to 100", kind = "plot",
  why = "Grey out everything except what you want the reader to look at, and rebase every group so its first period equals 100.",
  args = c("`highlight`: group name(s) to emphasise", "`index`: `TRUE` rebases each group to 100 at its first period"),
  code = 'panel_line(gf, "invest", by = "company", highlight = "1", index = TRUE)'),
 list(id = "line_period", h = "Coarsen time: quarters to years", kind = "plot",
  why = "`period` changes the time unit, and `fun_time` says how each individual's quarters combine: here the yearly total of each tourism flow, averaged by state.",
  args = c("`period = \"year\"`", "`fun_time = \"sum\"`: flows add up; use `\"last\"` for stocks and cumulative counts"),
  code = 'panel_line(tour, "Trips", by = "State", period = "year", fun_time = "sum")'),
 list(id = "line_p90", h = "A different summary, and a privacy floor", kind = "plot",
  why = "Show the 90th percentile instead of the mean, and hide any state-year with fewer than 30 individuals. The footer says groups were hidden.",
  args = c("`fun_group = \"p90\"`", "`min_n = 30`"),
  code = 'panel_line(tour, "Trips", by = "State", period = "year", fun_group = "p90", min_n = 30)'),
 list(id = "line_facet", h = "Small multiples and a log scale", kind = "plot",
  why = "One panel per group with free y axes; `log = TRUE` is useful when groups differ by orders of magnitude.",
  args = c("`facet = TRUE`", "`log = TRUE`"),
  code = 'panel_line(gm, "gdpPercap", by = "continent", facet = TRUE, log = TRUE)'),
 list(id = "heat", h = "Heatmap: groups by time", kind = "plot",
  why = "Rows are groups, columns are periods, colour is the value. Rows are sorted by level. With `by = NULL` the rows are individuals.",
  args = c("`by`, `period`, `fun_time`, `fun_group` as above", "`max_rows`: rows shown when rows are individuals (default 40)"),
  code = 'panel_heatmap(tour, "Trips", by = "State", period = "year")'),
 list(id = "heat_div", h = "Heatmap of individuals, diverging colours", kind = "plot", h_in = 7,
  why = "With `by = NULL` every row is one individual (here 30 of 142 countries, evenly spaced by level). `diverge` centres the colour scale on the overall mean, so blue is below average and red above.",
  args = c("`by = NULL`: rows are individuals", "`max_rows`: how many rows to show", "`diverge = TRUE`"),
  code = 'panel_heatmap(gm, "lifeExp", max_rows = 30, diverge = TRUE)'),
 list(id = "spag", h = "Spaghetti: individuals and the average", kind = "plot",
  why = "Thin lines are individuals, the bold line is the group summary. A log axis keeps small firms visible next to large ones.",
  args = c("`n_ids`: how many individual lines to draw (random sample, reproducible with `seed`)", "`log = TRUE`"),
  code = 'panel_spaghetti(gf, "invest", log = TRUE)'),
 list(id = "tracking", h = "Tracking: a series and its rolling average", kind = "plot",
  why = "Cumulative counts per country become a weekly series: each country's last value of the week, summed across countries, with a 4-week rolling average.",
  args = c("`window`: periods in the rolling average", "`fun_time = \"last\"`, `fun_group = \"sum\"`"),
  code = 'panel_tracking(covid, "Confirmed", period = "week", fun_time = "last", fun_group = "sum", window = 4)'),
 list(id = "band", h = "Band: the spread across individuals", kind = "plot",
  why = "The median line with a shaded percentile band shows spread, not just the centre. The headline reports whether the spread widened.",
  args = c("`lower`, `upper`: band edges (`\"p10\"`, `\"p90\"`, ...)", "`centre`: line summary (default `\"median\"`)"),
  code = 'panel_band(nls, "ln_wage", by = "race", lower = "p10", upper = "p90")'),
 list(id = "bar", h = "Bars: ranked groups", kind = "plot",
  why = "Time is collapsed (`period = \"all\"`). Names sit inside long bars; group sizes are in the subtitle.",
  args = c("`top_n`: groups shown (default 15)", "`decreasing`: sort order"),
  code = 'panel_bar(tour, "Trips", by = "State")'),
 list(id = "stacked", h = "Stacked bars: composition", kind = "plot",
  why = "Several measures stacked within each group. Segment labels that would not fit are hidden.",
  args = c("`vars`: two or more columns", "`min_label`: smallest share of the longest bar that gets a label"),
  code = 'panel_stacked(gf, c("invest", "kstock"), by = "company", top_n = 6)'),
 list(id = "dist", h = "Distribution of individuals", kind = "plot",
  why = "Each individual's average over time, then the distribution across individuals, by group.",
  args = c("`period = \"all\"`, `fun_time = \"mean\"`"),
  code = 'panel_distribution(nls, "ln_wage", by = "race")'),
 list(id = "style", h = "Style, tag, title and source", kind = "plot",
  why = "Five looks ship with the package: `economist` (default), `ft`, `clean`, `dark`, `mono`. Any computed text can be overridden. The numbered square is for figure references.",
  args = c("`style`: one of `panel_styles()` (or `use_panel_style(\"ft\")` for the session)", "`tag`: number or label in the top-right square", "`title`, `subtitle`, `source`"),
  code = 'panel_bar(tour, "Trips", by = "State", style = "ft", tag = 2,
          title = "New South Wales and Victoria dominate", source = "Tourism Research Australia, 1998-2017")'),
 list(id = "figure", h = "Numbered figure from several charts", kind = "fig", w = 14, h_in = 9,
  why = "`panel_figure()` lays charts out under one headline, numbers the panels and shares one source and notes footer.",
  args = c("`ncol`, `heights`, `widths`: layout", "`title`, `subtitle`, `source`, `notes`: shared text", "`tags = TRUE`: number the panels"),
  code = 'fig <- panel_figure(
  list(panel_line(gm, "lifeExp", by = "continent"),
       panel_bar(tour, "Trips", by = "State"),
       panel_band(nls, "ln_wage", by = "race", lower = "p10", upper = "p90"),
       panel_heatmap(tour, "Trips", by = "Purpose")),
  title = "Four views, one grammar", subtitle = "The same panelviz calls on three different panels",
  source = "Gapminder; Tourism Research Australia; US Bureau of Labor Statistics",
  notes = "Individuals are countries, tourism flows and women respectively.")
save_panel(fig, "figure.png", width = 14, height = 9)'),
 list(id = "table", h = "Get the numbers behind any chart", kind = "text",
  why = "Every chart takes `return = \"table\"` and hands back exactly what it drew.",
  args = c("`return = \"table\"`"),
  code = 'panel_line(gm, "lifeExp", by = "continent", return = "table")')
)

md <- c("<!-- examples:start (generated by data-raw/readme_examples.R) -->", "",
        "Every command below is the one that produced the output next to it. First, the data:", "",
        "```r", setup, "```", "")
for (e in ex) {
  md <- c(md, sprintf("### %s", e$h), "", e$why, "")
  if (length(e$args)) md <- c(md, paste0("- ", e$args), "")
  md <- c(md, "```r", e$code, "```", "")
  if (e$kind == "text") {
    out <- capture.output(res <- eval(parse(text = e$code)))
    if (!length(out) && !is.null(res)) out <- capture.output(print(res))
    md <- c(md, "```", out, "```", "")
  } else {
    fn <- sprintf("ex_%s.png", e$id)
    if (e$kind == "fig") {
      eval(parse(text = e$code))
      file.copy("figure.png", file.path(figdir, fn), overwrite = TRUE); unlink("figure.png")
    } else {
      p <- eval(parse(text = e$code)); save_panel(p, file.path(figdir, fn), width = 9, height = e$h_in %||% 5, dpi = 100)
    }
    md <- c(md, sprintf('<img src="man/figures/%s" width="%d" alt="%s">', fn, if (e$kind == "fig") 760 else 640, e$h), "")
  }
}
md <- c(md, "<!-- examples:end -->")
writeLines(md, "data-raw/out/examples.md")
rd <- readLines("README.md")
a <- grep("<!-- examples:start", rd, fixed = TRUE); b <- grep("<!-- examples:end -->", rd, fixed = TRUE)
if (length(a) == 1 && length(b) == 1) writeLines(c(rd[seq_len(a - 1)], md, rd[-seq_len(b)]), "README.md") else message("markers not found; see data-raw/out/examples.md")
