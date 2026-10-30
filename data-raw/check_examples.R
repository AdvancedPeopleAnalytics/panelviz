# Runs every downloaded dataset through import -> aggregate -> plot.
# Usage: Rscript data-raw/check_examples.R   (after data-raw/fetch.R)
suppressMessages({pkgload::load_all(".", quiet = TRUE); library(ggplot2)})
raw <- "data-raw/raw"; out <- "data-raw/out"; dir.create(out, FALSE)
save <- function(p, name, w = 9, h = 5) ggsave(file.path(out, paste0(name, ".png")), p, width = w, height = h, dpi = 100, bg = "white")
csv <- function(f) readr::read_csv(file.path(raw, f), show_col_types = FALSE)

cases <- list(
  nlswork    = list(d = file.path(raw, "nlswork.dta"), id = "idcode", time = "year", var = "ln_wage", by = "race"),
  grunfeld   = list(d = file.path(raw, "grunfeld.dta"), id = "company", time = "year", var = "invest", by = NULL),
  abdata     = list(d = file.path(raw, "abdata.dta"), id = "id", time = "year", var = "emp", by = "ind"),
  Gasoline   = list(d = file.path(raw, "Gasoline.csv"), id = "country", time = "year", var = "lgaspcar", by = NULL),
  Fatalities = list(d = file.path(raw, "Fatalities.csv"), id = "state", time = "year", var = "fatal", by = "jail"),
  tourism    = list(d = file.path(raw, "tourism.csv"), id = c("Region", "State", "Purpose"), time = "Quarter", var = "Trips", by = "Purpose")
)
for (n in names(cases)) {
  k <- cases[[n]]
  p <- read_panel(k$d, id = all_of(k$id), time = all_of(k$time))
  m <- panel_meta(p)
  cat(sprintf("%-11s ids=%-5d periods=%-3d kind=%-8s freq=%-8s balanced=%s range=%s..%s\n",
              n, m$n_ids, m$n_periods, m$kind, m$freq, m$balanced, m$range[1], m$range[2]))
  save(panel_line(p, k$var, by = k$by), paste0(n, "_line"))
  save(panel_heatmap(p, k$var, by = k$by), paste0(n, "_heat"))
  save(panel_spaghetti(p, k$var, by = k$by), paste0(n, "_spag"))
}
# Different time encodings of the same kind of data
p <- read_panel(file.path(raw, "tourism.csv"), id = c(Region, State, Purpose), time = Quarter)
save(panel_line(p, "Trips", by = "State", period = "year", fun_time = "sum"), "tourism_yearly_sum")

# ---- stage 2 charts, wide, daily ---------------------------------------------
g <- read_panel(file.path(raw, "grunfeld.dta"), id = company, time = year)
save(panel_tracking(g, "invest"), "grunfeld_tracking")
save(panel_band(read_panel(file.path(raw, "nlswork.dta"), id = idcode, time = year), "ln_wage", by = "race", lower = "p10", upper = "p90"), "nlswork_band")
save(panel_bar(p, "Trips", by = "State"), "tourism_bar")
save(panel_stacked(p, c("Trips"), by = "State"), "tourism_stacked1")
n <- read_panel(file.path(raw, "nlswork.dta"), id = idcode, time = year)
save(panel_distribution(n, "ln_wage", by = "race"), "nlswork_dist")
save(panel_spaghetti(g, "invest", log = TRUE), "grunfeld_spag_log")
save(panel_line(g, "invest", by = "company", highlight = "1", index = TRUE), "grunfeld_highlight_index")

# wide (Stata reshape example): inc80 inc81 inc82 / ue80 ue81 ue82
w <- as_panel_wide(haven::read_dta(file.path(raw, "reshape1.dta")), id, cols = c(starts_with("inc"), starts_with("ue")),
                   names_pattern = "^(inc|ue)(\\d+)$")
print(panel_meta(w)[c("n_ids", "n_periods", "kind")])
# daily: covid cumulative counts -> last value in the month, then mean across countries
cv <- read_panel(file.path(raw, "countries-aggregated.csv"), id = Country, time = Date)
cat(sprintf("covid       ids=%d periods=%d freq=%s\n", panel_meta(cv)$n_ids, panel_meta(cv)$n_periods, panel_meta(cv)$freq))
save(panel_line(cv, "Deaths", period = "month", fun_time = "last", fun_group = "sum"), "covid_deaths_monthly")
gm <- read_panel(file.path(raw, "gapminderDataFiveYear.csv"), id = country, time = year)
save(panel_line(gm, "lifeExp", by = "continent"), "gapminder_life")
