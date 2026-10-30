# Downloads public panel datasets with deliberately different id/time encodings.
dir.create("raw", showWarnings = FALSE)
src <- c(
  nlswork   = "https://www.stata-press.com/data/r18/nlswork.dta",   # idcode, year (integer), unbalanced
  grunfeld  = "https://www.stata-press.com/data/r18/grunfeld.dta",  # company, year; balanced
  abdata    = "https://www.stata-press.com/data/r18/abdata.dta",    # id, year
  invest2   = "https://www.stata-press.com/data/r18/invest2.dta",   # company, time
  Gasoline  = "https://vincentarelbundock.github.io/Rdatasets/csv/plm/Gasoline.csv",
  EmplUK    = "https://vincentarelbundock.github.io/Rdatasets/csv/plm/EmplUK.csv",
  Fatalities= "https://vincentarelbundock.github.io/Rdatasets/csv/AER/Fatalities.csv",
  covid     = "https://raw.githubusercontent.com/datasets/covid-19/main/data/countries-aggregated.csv", # daily, ISO dates
  reshape1  = "https://www.stata-press.com/data/r18/reshape1.dta",  # WIDE: inc80 inc81 ...
  gapminder = "https://raw.githubusercontent.com/plotly/datasets/master/gapminderDataFiveYear.csv", # 5-year steps
  tourism   = "https://vincentarelbundock.github.io/Rdatasets/csv/tsibble/tourism.csv"
)
for (n in names(src)) {
  f <- file.path("raw", basename(src[[n]]))
  if (!file.exists(f)) try(download.file(src[[n]], f, quiet = TRUE, mode = "wb"))
  cat(n, file.exists(f), if (file.exists(f)) file.size(f), "\n")
}
