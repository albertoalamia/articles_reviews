// ET, sensitivity (ii') (plan §5): the v1.0 primary. Shared donkey intercept u ~ Normal(0, tau) and a
// condition-specific residual SD: y = b0 + b_cond[c] + b_ord[o] + u[donkey] + e, e ~ Normal(0, sigma[c]).
// Same likelihood as glmmTMB(y ~ condition + order + (1 | donkey), dispformula = ~ condition).
// Written in its marginal form (plan §7, 2026-11-18, S6): the three values of a donkey are MVN with
// Sigma = tau^2 * 1 1' + diag(sigma^2), the special case of et_mvn.stan with equal covariances. The
// centred/non-centred versions with sampled u could not be sampled on the example replicate (sigma_control
// at the boundary: divergences, E-BFMI 0.14, R-hat 1.04 on sigma_control even at adapt_delta 0.99); the
// marginal form has no funnel because tau^2 keeps Sigma positive definite as sigma_control -> 0.
// Priors: plan §5 (v1.0 values). Switches: prior_only, prior_scale, pooled (one residual sigma).
data {
  int<lower=1> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> donkey;
  array[N] int<lower=1, upper=3> cond;
  array[N] int<lower=1, upper=3> ord;
  vector[N] y;
  int<lower=0, upper=1> prior_only;
  real<lower=0> prior_scale;
  int<lower=0, upper=1> pooled;
}
transformed data {
  array[J] vector[3] Y;
  array[J, 3] int ord_jc;
  array[J, 3] int seen = rep_array(0, J, 3);
  for (n in 1:N) {
    Y[donkey[n]][cond[n]] = y[n];
    ord_jc[donkey[n], cond[n]] = ord[n];
    seen[donkey[n], cond[n]] += 1;
  }
  for (j in 1:J) for (c in 1:3)
    if (seen[j, c] != 1) reject("donkey ", j, ", condition ", c, ": ", seen[j, c], " rows; exactly one required");
}
parameters {
  real b0;
  vector[2] b_cond;
  vector[2] b_ord;
  real<lower=0> tau;
  vector<lower=0>[pooled ? 1 : 3] sigma_raw;
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[3] sigma = pooled ? rep_vector(sigma_raw[1], 3) : sigma_raw;
  matrix[3, 3] L_Sigma = cholesky_decompose(add_diag(rep_matrix(square(tau), 3, 3), square(sigma)));
  array[J] vector[3] mu;
  for (j in 1:J) mu[j] = b0 + bc + bo[ord_jc[j]];
}
model {
  b0 ~ normal(35, 2 * prior_scale);
  b_cond ~ normal(0, 2 * prior_scale);
  b_ord ~ normal(0, 2 * prior_scale);
  tau ~ normal(0, 2 * prior_scale);
  sigma_raw ~ normal(0, 2 * prior_scale);
  if (!prior_only) Y ~ multi_normal_cholesky(mu, L_Sigma);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);
  real diff_pos = b_cond[1];
  real diff_neg = b_cond[2];
  real diff_pos_neg = b_cond[1] - b_cond[2];
  // E3 in the shared-intercept parameterisation: tau, per-condition ICC, and the implied within-donkey
  // correlations tau^2 / sqrt((tau^2 + sigma_c^2)(tau^2 + sigma_c'^2)), comparable with rho_* of et_mvn.stan
  vector[3] icc = square(tau) ./ (square(tau) + square(sigma));
  real rho_cp = square(tau) / sqrt((square(tau) + square(sigma[1])) * (square(tau) + square(sigma[2])));
  real rho_cn = square(tau) / sqrt((square(tau) + square(sigma[1])) * (square(tau) + square(sigma[3])));
  real rho_pn = square(tau) / sqrt((square(tau) + square(sigma[2])) * (square(tau) + square(sigma[3])));
  vector[N] y_rep;
  vector[J] log_lik;
  {
    array[J] vector[3] Y_rep = multi_normal_cholesky_rng(mu, L_Sigma);
    for (n in 1:N) y_rep[n] = Y_rep[donkey[n]][cond[n]];
    for (j in 1:J) log_lik[j] = multi_normal_cholesky_lpdf(Y[j] | mu[j], L_Sigma);
  }
}
