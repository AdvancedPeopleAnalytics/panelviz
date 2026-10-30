test_that("invalid panel structure fails with useful messages", {
  d <- data.frame(id = c("a", "b"), t = 2001:2002, y = 1:2)
  expect_error(as_panel(d[FALSE, ], id, t), "at least one row")
  expect_error(as_panel(d, id, c(t, y)), "exactly one")
  expect_error(as_panel(d, tidyselect::any_of("absent"), t), "at least one column")
  expect_error(as_panel(transform(d, .id = id), id, t), "already exist")
  expect_error(as_panel(transform(d, id = NA_character_), id, t), "missing id")
  expect_error(as_panel(transform(d, t = NA_integer_), id, t), "missing time")
  expect_error(panel_meta(d), "as_panel")
  expect_error(as_panel_wide(d, id, cols = tidyselect::any_of("absent")), "no columns")
})

test_that("composite identifiers reject missing values and cannot collide", {
  d <- data.frame(a = c("x | y", "x", "x\\", "x"),
                  b = c("z", "y | z", "y", "\\y"), t = 1, y = 1:4)
  p <- as_panel(d, c(a, b), t)
  expect_equal(panel_meta(p)$n_ids, 4)
  expect_equal(nrow(panel_aggregate(p, "y", by = ".id")), 4)
  d$b[1] <- NA_character_
  expect_error(as_panel(d, c(a, b), t), "missing id")
})

test_that("duplicates can be retained and panel summaries print", {
  d <- data.frame(id = c("a", "a", "b"), t = c(1, 1, 2), y = c(2, 4, 8))
  p <- as_panel(d, id, t, dups = "keep")
  expect_equal(panel_meta(p)$dups, 1)
  expect_equal(panel_aggregate(p, "y")$y, c(3, 8))
  expect_output(print(p), "unbalanced")
  d$t <- c(2001, 2001, 2002)
  expect_output(print(as_panel(d, id, t, dups = "keep")), "2001-01-01")
})

test_that("numeric measures are detected without aggregating standard keys", {
  p <- as_panel(data.frame(id = c("a", "b"), t = 1, y = c(2, 4), g = "all"), id, t)
  tab <- panel_aggregate(p)
  expect_named(tab, c(".period", "t", "y", ".n"))
  expect_equal(tab$y, 3)
})

test_that("local file readers preserve the panel and source", {
  d <- data.frame(id = rep(c("a", "b"), each = 2), t = rep(2001:2002, 2), y = 1:4)
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE))
  rds <- file.path(root, "panel.rds")
  saveRDS(d, rds)
  expect_equal(read_panel(rds, id, t), as_panel(d, id, t, source = basename(rds)))
  expect_error(read_panel(file.path(root, "panel.xlsx"), id, t), "Unsupported")
  skip_if_not_installed("readr")
  for (ext in c("csv", "tsv", "txt")) {
    f <- file.path(root, paste0("panel.", ext))
    readr::write_delim(d, f, delim = if (ext == "tsv") "\t" else ",")
    p <- read_panel(f, id, t, source = "Local fixture")
    expect_equal(panel_meta(p)$n_ids, 2)
    expect_equal(panel_meta(p)$source, "Local fixture")
    expect_equal(p$y, d$y)
  }
})

test_that("Stata and SPSS labels survive file import and aggregation", {
  skip_if_not_installed("haven")
  d <- data.frame(id = rep(1:2, each = 2), t = rep(2001:2002, 2),
                  g = haven::labelled(c(1, 1, 2, 2), c(North = 1, South = 2)),
                  y = haven::labelled(c(2, 4, 6, 8), label = "Annual income"))
  d$id <- haven::labelled(d$id, c(Alice = 1, Bob = 2))
  for (ext in c("dta", "sav")) {
    f <- tempfile(fileext = paste0(".", ext))
    if (ext == "dta") haven::write_dta(d, f) else haven::write_sav(d, f)
    p <- read_panel(f, id, t)
    expect_equal(unique(p$.id), c("Alice", "Bob"))
    tab <- panel_aggregate(p, "y", by = "g", period = "all")
    expect_equal(tab$g, c("North", "South"))
    expect_equal(tab$y, c(3, 7))
    expect_equal(attr(tab, "panel_info")$labels$y, "Annual income")
    unlink(f)
  }
})
