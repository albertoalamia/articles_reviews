# model_dag.R — the directed acyclic graph of a Bayesian model (protocol H4e): one node per
# quantity of the Stan program, hyperparameters at the left, observed data at the right, as in
# the DAGs of Levy & Mislevy, *Bayesian Psychometric Modeling*, and in the Metilfenidato
# manuscript (ggdag). Indices are carried in the labels (plotmath), not in plates.
#
# model_dag(nodes, edges, title = NULL, node_size = 11, text_size = 2.8) -> ggplot
#   nodes : name, label (plotmath string, e.g. "beta[c]", "y[ic]", "N(0, 1)"), group, x, y
#           group in {"hyperparameter", "parameter", "derived", "covariate", "observed"}:
#           hyperparameter = fixed prior constants; parameter = sampled; derived = deterministic
#           function of parameters (transformed parameters / generated quantities);
#           covariate = observed design variable; observed = the data the likelihood is on
#   edges : from, to (node names)
# Each node should correspond to a line of the Stan program; the review caption names the file.

model_dag <- function(nodes, edges, title = NULL, node_size = 11, text_size = 2.8) {
  groups <- c("hyperparameter", "parameter", "derived", "covariate", "observed")
  stopifnot(all(c("name", "label", "group", "x", "y") %in% names(nodes)),
            all(c("from", "to") %in% names(edges)),
            all(nodes$group %in% groups),
            all(edges$from %in% nodes$name), all(edges$to %in% nodes$name),
            !anyDuplicated(nodes$name))
  txt <- paste0("dag {\n",
                paste(sprintf('%s [pos="%s,%s"]', nodes$name, nodes$x, nodes$y), collapse = "\n"), "\n",
                paste(edges$from, "->", edges$to, collapse = "\n"), "\n}")
  g <- dagitty::dagitty(txt)
  d <- ggdag::tidy_dagitty(g)$data
  d <- merge(d, nodes[, c("name", "label", "group")], by = "name", all.x = TRUE, sort = FALSE)
  d$group <- factor(d$group, levels = groups)
  fills <- c(hyperparameter = "#ffe66d", parameter = "#8fd3c9", derived = "grey88",
             covariate = "#cfe3f7", observed = "#f0897a")
  hyper <- nodes[nodes$group == "hyperparameter", ]
  inner <- d[d$group != "hyperparameter", ]
  p <- ggplot2::ggplot(d, ggplot2::aes(x = x, y = y, xend = xend, yend = yend)) +
    ggdag::geom_dag_edges(edge_width = 0.35, edge_colour = "grey35") +
    ggdag::geom_dag_point(ggplot2::aes(fill = group, size = group), shape = 21, colour = "grey25") +
    ggdag::geom_dag_text(data = inner, ggplot2::aes(label = label), parse = TRUE, colour = "black", size = text_size) +
    # prior constants are written beside their (small) node, where they fit
    ggplot2::geom_text(data = hyper, ggplot2::aes(x = x - 0.16, y = y, label = label), inherit.aes = FALSE,
                       parse = TRUE, hjust = 1, size = text_size * 0.95, colour = "grey20") +
    ggplot2::scale_fill_manual(values = fills, drop = FALSE, name = NULL,
                               labels = c("prior constant", "parameter", "derived", "covariate", "data")) +
    ggplot2::scale_size_manual(values = c(hyperparameter = node_size * 0.45, parameter = node_size, derived = node_size,
                                          covariate = node_size, observed = node_size), guide = "none") +
    ggplot2::expand_limits(x = range(nodes$x) + c(-1.2, 0.4), y = range(nodes$y) + c(-0.4, 0.4)) +
    ggdag::theme_dag_blank() +
    ggplot2::theme(legend.position = "bottom", plot.title = ggplot2::element_text(size = 10, face = "bold")) +
    ggplot2::guides(fill = ggplot2::guide_legend(override.aes = list(size = 4)))
  if (!is.null(title)) p <- p + ggplot2::ggtitle(title)
  p
}
