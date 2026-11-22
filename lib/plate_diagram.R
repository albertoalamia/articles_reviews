# plate_diagram.R — graphical models in plate notation for the Stan programs (protocol H4e).
#
# A diagram is specified as three data frames and drawn with ggplot2, so that it renders in HTML
# and PDF through the usual R path and needs no graph engine:
#   nodes : name, label (plotmath or plain), x, y, type in {"data", "param", "const", "derived"}
#   edges : from, to (node names); optional lty ("solid" default, "dashed" for deterministic links)
#   plates: name, label, x0, y0, x1, y1 (rectangle in the node coordinates)
# Conventions: data nodes shaded, parameters open circles, prior constants small dots, derived
# quantities dashed circles. Each node should correspond to one line of the Stan program; the
# caption in review.qmd names the file.
#
# plate_diagram(nodes, edges, plates = NULL, node_r = 0.28, label_size = 3.4) -> ggplot object

plate_diagram <- function(nodes, edges, plates = NULL, node_r = 0.28, label_size = 3.4) {
  stopifnot(all(c("name", "label", "x", "y", "type") %in% names(nodes)),
            all(c("from", "to") %in% names(edges)),
            all(edges$from %in% nodes$name), all(edges$to %in% nodes$name),
            all(nodes$type %in% c("data", "param", "const", "derived")))
  if (is.null(edges$lty)) edges$lty <- "solid"
  e <- merge(edges, nodes[, c("name", "x", "y")], by.x = "from", by.y = "name")
  e <- merge(e, nodes[, c("name", "x", "y")], by.x = "to", by.y = "name", suffixes = c("", "_end"))
  # shorten each edge so that the arrow stops at the node border
  d <- sqrt((e$x_end - e$x)^2 + (e$y_end - e$y)^2)
  r_from <- ifelse(nodes$type[match(e$from, nodes$name)] == "const", node_r * 0.35, node_r)
  r_to   <- ifelse(nodes$type[match(e$to, nodes$name)] == "const", node_r * 0.35, node_r)
  e$xs <- e$x + (e$x_end - e$x) * r_from / d;  e$ys <- e$y + (e$y_end - e$y) * r_from / d
  e$xe <- e$x_end - (e$x_end - e$x) * r_to / d; e$ye <- e$y_end - (e$y_end - e$y) * r_to / d
  circle <- function(cx, cy, r, n = 60) {
    t <- seq(0, 2 * pi, length.out = n)
    data.frame(x = cx + r * cos(t), y = cy + r * sin(t))
  }
  circles <- do.call(rbind, lapply(seq_len(nrow(nodes)), function(i) {
    r <- if (nodes$type[i] == "const") node_r * 0.35 else node_r
    cbind(circle(nodes$x[i], nodes$y[i], r), name = nodes$name[i], type = nodes$type[i])
  }))
  fill_map <- c(data = "grey80", param = "white", const = "grey30", derived = "white")
  lty_map  <- c(data = "solid", param = "solid", const = "solid", derived = "dashed")
  p <- ggplot2::ggplot()
  if (!is.null(plates) && nrow(plates) > 0) {
    p <- p +
      ggplot2::geom_rect(data = plates, ggplot2::aes(xmin = x0, xmax = x1, ymin = y0, ymax = y1),
                         fill = NA, colour = "grey40", linewidth = 0.4) +
      ggplot2::geom_text(data = plates, ggplot2::aes(x = x1 - 0.08, y = y0 + 0.12, label = label),
                         hjust = 1, vjust = 0, size = label_size * 0.85, colour = "grey30", parse = TRUE)
  }
  p <- p +
    ggplot2::geom_segment(data = e, ggplot2::aes(x = xs, y = ys, xend = xe, yend = ye, linetype = lty),
                          arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed"),
                          linewidth = 0.4, colour = "grey20", show.legend = FALSE) +
    ggplot2::geom_polygon(data = circles,
                          ggplot2::aes(x = x, y = y, group = name, fill = type, linetype = type),
                          colour = "grey20", linewidth = 0.4, show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = fill_map) +
    ggplot2::scale_linetype_manual(values = c(lty_map, solid = "solid", dashed = "dashed")) +
    ggplot2::geom_text(data = nodes[nodes$type != "const", ],
                       ggplot2::aes(x = x, y = y, label = label), size = label_size, parse = TRUE) +
    ggplot2::geom_text(data = nodes[nodes$type == "const", ],
                       ggplot2::aes(x = x, y = y + node_r * 0.9, label = label), size = label_size * 0.8, parse = TRUE) +
    ggplot2::coord_equal(clip = "off") +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(6, 6, 6, 6))
  p
}
