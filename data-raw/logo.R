# Logo options in the tinyCode lineage (square-pixel SVG, crisp edges) plus a tidyverse-style hex.
# Rscript data-raw/logo.R   -> data-raw/out/logo-options/*.svg and a contact sheet
# The chosen logo is option 2 (panel grid), copied to assets/logo.svg
seq5 <- c(a = "#cfe6f2", b = "#8fc6e3", c = "#00a0dc", d = "#00587a", e = "#00293d")
navy <- "#00405c"; cyan <- "#00a0dc"; steel <- "#6b8ea4"; red <- "#e3120b"; pale <- "#d6e4ec"

grid_rects <- function(rows, pal, cell = 20) {
  out <- list()
  for (r in seq_along(rows)) {
    ch <- strsplit(rows[r], "")[[1]]
    for (cc in seq_along(ch)) if (ch[cc] != ".")
      out[[length(out) + 1]] <- data.frame(x = (cc - 1) * cell, y = (r - 1) * cell, w = cell, h = cell, fill = pal[[ch[cc]]])
  }
  do.call(rbind, out)
}

opts <- list(
  heat_p = list(label = "1  Heat-P\npixel P, heat-map shades,\none highlighted individual",
    rects = grid_rects(c("aaaa.", "b.Rb.", "cccc.", "d....", "e...."),
                       list(a = navy, b = "#00587a", c = cyan, d = steel, e = "#b5dcee", R = red))),
  panel_grid = list(label = "2  Panel grid\nindividuals x time tiles,\none trajectory in red",
    rects = grid_rects(c("aabcR", "bbcRd", "abRcc", "RRabc"), c(as.list(seq5), R = red))),
  tag_bars = list(label = "3  Tag + bars\nEconomist red tag over\nrising tile bars",
    rects = grid_rects(c("RR...", ".....", "....R", "...aa", ".b.aa", "bbbaa", "bbbaa"),
                       list(R = red, a = navy, b = cyan))),
  panel_p = list(label = "4  Panel P\npixel P standing on a\npale panel grid",
    rects = { bg <- grid_rects(rep("ppppp", 5), list(p = pale))
              p <- grid_rects(c("aaaa.", "a.Ra.", "aaaa.", "a....", "a...."), list(a = navy, R = red))
              rbind(bg, p) }),
  hex = list(label = "5  Hex sticker\ntidyverse-style hex with\nthe panel grid inside", hex = TRUE,
    rects = { g <- grid_rects(c("aabcR", "bbcRd", "abRcc", "RRabc"), c(as.list(seq5), R = red))
              g$x <- g$x * 0.8 + 10; g$y <- g$y * 0.8 + 36; g$w <- g$w * 0.8; g$h <- g$h * 0.8; g })
)

hex_pts <- function() { # pointy-top hexagon in a 100 x 115 box
  cbind(x = c(50, 100, 100, 50, 0, 0), y = c(0, 28.75, 86.25, 115, 86.25, 28.75))
}

svg_for <- function(o) {
  r <- o$rects
  rect_txt <- paste0(sprintf('<rect x="%g" y="%g" width="%g" height="%g" fill="%s"/>', r$x, r$y, r$w, r$h, r$fill), collapse = "")
  if (isTRUE(o$hex)) {
    pts <- paste(sprintf("%g,%g", hex_pts()[, 1], hex_pts()[, 2]), collapse = " ")
    return(sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -4 108 123" width="108" height="123"><polygon points="%s" fill="%s" stroke="%s" stroke-width="3"/><g shape-rendering="crispEdges">%s</g></svg>', pts, navy, cyan, rect_txt))
  }
  w <- max(r$x + r$w); h <- max(r$y + r$h)
  sprintf('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-10 -10 %g %g" width="%g" height="%g" shape-rendering="crispEdges">%s</svg>', w + 20, h + 20, w + 20, h + 20, rect_txt)
}
dir.create("data-raw/out/logo-options", recursive = TRUE, showWarnings = FALSE)
for (n in names(opts)) writeLines(svg_for(opts[[n]]), file.path("data-raw/out/logo-options", paste0(n, ".svg")))

# contact sheet: each option on a light and on a dark background
draw_opt <- function(o, bg) {
  r <- o$rects; fam <- tryCatch(panelfont(), error = function(e) "")
  grid::pushViewport(grid::viewport(width = 0.92, height = 0.92)); grid::grid.rect(gp = grid::gpar(fill = bg, col = NA))
  if (isTRUE(o$hex)) { W <- 108; H <- 123; ox <- 4; oy <- 4 } else { W <- max(r$x + r$w) + 20; H <- max(r$y + r$h) + 20; ox <- 10; oy <- 10 }
  s <- 0.86 * min(1 / W, 1 / H)
  grid::pushViewport(grid::viewport(width = grid::unit(W * s, "npc"), height = grid::unit(H * s, "npc"),
                                    xscale = c(0, W), yscale = c(H, 0)))
  if (isTRUE(o$hex)) { p <- hex_pts(); grid::grid.polygon(p[, 1] + ox, p[, 2] + oy, default.units = "native",
                                  gp = grid::gpar(fill = navy, col = cyan, lwd = 2)) }
  grid::grid.rect(r$x + ox, r$y + oy, r$w, r$h, just = c("left", "top"), default.units = "native",
                  gp = grid::gpar(fill = r$fill, col = NA))
  grid::popViewport(2)
}
ragg::agg_png("data-raw/out/logo-options/contact-sheet.png", width = 2000, height = 1100, res = 150)
grid::grid.newpage(); grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
lay <- grid::grid.layout(3, length(opts), heights = grid::unit(c(1, 1, 0.42), "null"))
grid::pushViewport(grid::viewport(layout = lay))
for (i in seq_along(opts)) {
  grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = i)); draw_opt(opts[[i]], "white"); grid::popViewport()
  grid::pushViewport(grid::viewport(layout.pos.row = 2, layout.pos.col = i)); draw_opt(opts[[i]], "#0d1117"); grid::popViewport()
  grid::pushViewport(grid::viewport(layout.pos.row = 3, layout.pos.col = i))
  grid::grid.text(opts[[i]]$label, gp = grid::gpar(fontsize = 11, lineheight = 1.15, col = "grey20"))
  grid::popViewport()
}
grDevices::dev.off()
