# panelviz: what this project knows

- **Purpose:** R package that generalises the plotting machinery of `wpa` / `vivainsights` (both Microsoft, MIT; the
  user is a co-author) to any panel data. Declare id + time, auto-detect formats, two-stage aggregation, charts.
  Plan: stage 1 import hardening and stage 2 charts are done; **next is the refactor** that makes `wpa` and
  `vivainsights` depend on this package and turns their `create_*` functions into thin wrappers (audit and map first).
- **Name:** was `tidyPanel` until 2026-10-30, when `R CMD check --as-cran` found CRAN already has `TidyPanel`
  ("Universal Messy Panel Data Cleaner"; CRAN names are case-insensitive). Considered panelscape (user found it hard
  to understand) and ggpanel (free, but `gg` undersells a package that also imports and aggregates). The user chose
  **panelviz** as the most literal. It is free on CRAN; `panelView` on CRAN is a different, similar-sounding package
  (treatment-status plots), so the README says "not to be confused with panelView". The refactor needs this package
  on CRAN first (CRAN packages can only depend on CRAN packages); the user will talk to Martin Chan (wpa and
  vivainsights maintainer). Local folder and `.palace` name still say tidyPanel; the GitHub repo is
  `moralec/tidyPanel` until renamed (waiting for the user's yes).
- **Everything that matters is in `R/`:** `time.R` (format detection), `panel.R`/`wide.R`/`read.R` (import),
  `aggregate.R` (two-stage), `plot.R` (charts), `smart.R` (axis units, computed headlines), `style.R` (five looks,
  tag/number decorations, device font fallback), `figure.R` (numbered figures, `save_panel`).
- **Non-obvious decisions:**
  - Red tag and numbered squares are drawn at print/save time (`print`/`grid.draw` methods on class `panel_plot`),
    so charts stay ordinary ggplots but lose decorations inside patchwork.
  - ggproto layers cannot be copied (`ggproto(NULL, layer)` overflows the stack); font fallback blanks the layer
    font in place and restores it.
  - Two-digit years only for values 30-99; 0-99 would swallow plain 1..20 indices.
  - Group sizes live in subtitles, not axis labels (user preference).
- **README examples are generated:** `Rscript data-raw/readme_examples.R` runs every shown command and splices
  output and images into README between the `examples:` markers. Needs internet. Edit the examples there, not in README.
- **Test data:** `Rscript data-raw/fetch.R`, then `Rscript data-raw/check_examples.R` (8 public datasets).
- **Fonts:** best condensed face via `systemfonts`; on this Mac it is Avenir Next Condensed. Save with `ragg`.
- **v1.0.0 released 2026-10-30** (preview banner removed; tag `v1.0.0`, GitHub release with the source tarball). `R CMD check --as-cran` has only environment notes. Not on CRAN yet: `cran-comments.md` and `NEWS.md` exist.
- **Published** at github.com/moralec/panelviz (public, 2026-10-30). Logo: ; `assets/logo.svg` is the panel-grid logo (option 2), chosen by the user. `Rscript data-raw/logo.R` regenerates the options.
