## Test environments

* Windows 11 (x86_64-w64-mingw32), R 4.6.1, checked 2026-10-30

## R CMD check results

`R CMD check --as-cran --no-manual`: 0 errors | 0 warnings | 1 note.

CRAN incoming and remote checks were enabled and all suggested packages were
required. The only note is "New submission". This is the first CRAN submission.

A separate check including the PDF and HTML manuals reported both manuals OK,
with 0 errors, 0 warnings and 2 notes. The additional note concerned a
`lastMiKTeXException` file left in the temporary directory by the local MiKTeX
toolchain. The check without manual generation had no temporary-file note.

## Release summary

First release of a package for importing, aggregating and visualising panel data.

## What's new in this version

* Declare long or wide panels and import common file formats.
* Recognise common date, timestamp, Stata and numeric time encodings.
* Aggregate within individuals and then across groups, with a group-size floor.
* Draw eight chart types, compose figures and save charts in common formats.
* Provide automatic axes, data-derived titles and five chart styles.
* Harden identifier handling, missing-value line labels, numeric-index aggregation,
  random-number state preservation, figure layouts and device font fallback.
* Fit figure cells to their column width: headlines wrap where they are drawn,
  cell type and legends shrink to leave a readable plot area, and direct line
  labels stay inside the panel.
* Include a getting-started vignette covering the whole workflow on simulated data.

## Additional validation

* 275 test expectations passed, with no failures, warnings or skips.
* Local test coverage is 90.69% (93.90% before the figure-fitting change),
  increased from the initial 80.43%.
* Package documentation, DESCRIPTION, README and NEWS have no spelling findings
  using British English and an explicit technical word list.
* Documentation was regenerated with roxygen2 8.1.1 and is in sync.
* All seven URLs passed the URL check with a 30-second network timeout. The
  urlchecker default five-second timeout was insufficient for the CRAN website
  from this machine.
* A narrow two-column figure was rendered and inspected for headline wrapping,
  separation from numbered tags, label placement and legend layout, and the
  getting-started vignette was re-knit and checked.

## Reverse dependencies

No CRAN reverse dependencies were found in Depends, Imports, LinkingTo or
Suggests in the CRAN package index on 2026-10-30.

## Checks still required before submission

The added GitHub Actions matrix covers macOS, Windows and Ubuntu, with R release,
R-devel, R-oldrel-1 and the declared minimum R 4.1. These jobs have not yet run.
The quality workflow checks documentation, spelling, URLs and a 90% coverage floor.
Routine CI disables incoming-submission checks, which were tested explicitly
in the local run reported above.

Win-builder R-devel has not been requested. No version change or CRAN submission
has been performed.
