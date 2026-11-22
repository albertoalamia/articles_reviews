---
name: dagify
description: Draw the graph of a Bayesian model (protocol H4e) from a Stan program with lib/model_dag.R, in the Levy & Mislevy convention. Use when a review or plan needs the DAG of a stage 4 program, when a program changes, or when Alberto asks for "the DAG of the model".
---

# dagify — the model graph of a Stan program

"DAG" in this repository means the graph of the model itself: prior constants → parameters →
derived quantities → data, one node per quantity of the Stan program, as in Levy & Mislevy,
*Bayesian Psychometric Modeling*, ch. 11. It is **not** a causal diagram of the research
question. The causal structure stays as dagitty code in `notes/04_analysis_plan.md` §3b.4 and is
computed in the review (adjustment sets, paths), never drawn. Do not draw any other kind of
diagram without asking.

Helper: `lib/model_dag.R` → `model_dag(nodes, edges, title)`; tests in `lib/tests/`.
Parser: `tools/stan_to_dag.R` (base R, read-only, Claude may run it).

## Procedure

1. **Skeleton from the program.** From the repo root, inside the nix shell:
   ```
   Rscript tools/stan_to_dag.R <article>/stan/<model>.stan
   ```
   It prints `nodes` and `edges` as R code: one prior-constant node per `~` on a parameter
   with fixed arguments, an edge from every variable used on the right of a `~` or `=`, sizes
   and switches (`N`, `prior_only`, `prior_scale`) listed and left out, `y_rep` and `log_lik`
   left out, `target +=` lines listed for reading. Hierarchical priors (`u ~ normal(0, tau)`)
   give an edge from the parent, no constant node. Before a program exists (plan stage), build
   the same tables by hand from the plan's §3 and §5 and write "(planned)" in the title.

2. **Prune to what the reader needs.** Keep: every parameter with a prior, the derived
   quantities on the path from parameters to data (linear predictor, scale, covariance), the
   covariates that enter them, the data node(s), and the generated quantities that the review
   reports (the estimands of the parameter table, H4f). Drop: padding vectors
   (`bc = append_row(0, b_cond)` folds into the parameter node), predictive draws, bookkeeping.
   A non-centred effect keeps both nodes (`z`, `τ` → `u`). Every remaining node must correspond
   to a line of the file; the caption names the file.

3. **Labels (plotmath).** Parameters and data with indices as subscripts: `"beta[c]"`,
   `"y[ic]"`, `"h[gjk]"`. Greek names render as Greek. Argument lists go in string literals:
   `"N*'(0, 1)'"`, `"N^'+'*'(0, 1)'"` (half-normal from `<lower=0>`), `"LogN*'(log 0.004, 1.5)'"`,
   `"LKJ*'(2)'"`. Powers: `"phi^{-1/2}"`. Two quantities in one node: `"atop(RD[k], RR[k])"`.
   Drop `* prior_scale` from the labels; the sensitivity multiplier is said in the caption or
   the text. A prior that reads a data constant (`b_prior_sd`) is written with its value.

4. **Layout.** Columns: prior constants at x = 0 (their label is printed to the left of a small
   node), parameters at x = 1, derived quantities at x = 2–4 in the order of computation,
   covariates between the parameters and the quantity they enter, data at the right. Rows
   about 0.8–1.0 apart, parameters sharing a prior stacked under one constant node (one node,
   two edges). Keep edges from crossing by ordering rows; a shared linear predictor sits at the
   vertical centre. Defaults `node_size = 11`, `text_size = 2.8` fit a 6.5 × 4 inch figure
   with up to about 15 nodes; above that, split the program into two panels or raise
   `fig-height`.

5. **Check the drawing before it goes in the review.** Draw to the scratchpad with
   `ggsave(..., bg = "white")`, open the PNG, and verify: no label outside its node, no edge
   through a node, the observed node receives an edge from everything in its sampling
   statement, every parameter has a constant or a parent, node count matches step 2.

6. **Chunk in `review.qmd`** (section "The models, written out" → "What this review fits"),
   one chunk for all programs of the paper:
   ```
   #| label: fig-model-dags-<paperid>     # the fig- prefix is required
   #| message: false
   #| fig-width: 6.5
   #| fig-height: 4
   #| fig-dpi: 150                        # sharp when opened in the lightbox
   #| layout-ncol: 2
   #| fig-subcap:                         # one short line per program, else the caption repeats under each panel
   #|   - "..."
   #| fig-cap: "... one node per quantity of the Stan file (`stan/`): prior constants (yellow, beside the node), parameters (green), derived quantities (grey), covariates (blue), data (red). Indices: ..."
   source(here::here("lib/model_dag.R"))
   ```
   Refer to it in the prose with `@fig-model-dags-<paperid>`. Renaming a chunk label renames
   the files under `_freeze/<article>/review/figure-html|pdf/`; delete the old ones.

7. **Keep the plan in step.** `notes/04_analysis_plan.md` §3b.5 lists the nodes of each
   program. When a program is written or changed, redraw from the file and update the list.

## Hand-off

Claude writes the chunk and the scratch drawing; Alberto renders (`quarto render
<article>/review.qmd`). Then follow the `render-check` skill.
