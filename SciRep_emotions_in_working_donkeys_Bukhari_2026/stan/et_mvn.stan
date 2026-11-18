// ET, planned model (plan §3, v1.1): the three condition values of a donkey form one multivariate
// normal vector, (y_i1, y_i2, y_i3) ~ MVN(mu_i, Sigma), mu_ic = b0 + b_cond[c] + b_ord[o(i, c)],
// Sigma = diag(sigma) Omega diag(sigma) unstructured (three SDs in degC, three correlations).
// Same likelihood as glmmTMB(y ~ condition + order + us(0 + condition | donkey), dispformula = ~ 0)
// in R/02_fit_frequentist.R. The donkey vector u_i of plan §3 is integrated out analytically: the
// model has no residual term, so y_i - mu_i = u_i and sampling u would add 102 redundant parameters.
// Priors: plan §5 (LKJ(2) unchanged under prior_scale). Coding: cond 1 control, 2 positive,
// 3 negative; ord 1..3. Switches: prior_only; prior_scale (sensitivities i, i'); pooled
// (sensitivity iv: one sigma for the three conditions, correlations still free).
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
  vector[2] b_cond;                          // positive - control, negative - control (degC)
  vector[2] b_ord;                           // position 2 - 1, position 3 - 1
  vector<lower=0>[pooled ? 1 : 3] sigma_raw;
  cholesky_factor_corr[3] L_Omega;
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[3] sigma = pooled ? rep_vector(sigma_raw[1], 3) : sigma_raw;
  matrix[3, 3] L_Sigma = diag_pre_multiply(sigma, L_Omega);
  array[J] vector[3] mu;
  for (j in 1:J) mu[j] = b0 + bc + bo[ord_jc[j]];
}
model {
  b0 ~ normal(35, 2 * prior_scale);
  b_cond ~ normal(0, 2 * prior_scale);
  b_ord ~ normal(0, 2 * prior_scale);
  sigma_raw ~ normal(0, 2 * prior_scale);
  L_Omega ~ lkj_corr_cholesky(2);
  if (!prior_only) Y ~ multi_normal_cholesky(mu, L_Sigma);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);      // condition means (degC), typical donkey, averaged over order
  // E1, E2 (degC)
  real diff_pos = b_cond[1];
  real diff_neg = b_cond[2];
  real diff_pos_neg = b_cond[1] - b_cond[2];
  // E3: the within-donkey correlations between conditions
  matrix[3, 3] Omega = multiply_lower_tri_self_transpose(L_Omega);
  real rho_cp = Omega[1, 2];                 // control - positive
  real rho_cn = Omega[1, 3];                 // control - negative
  real rho_pn = Omega[2, 3];                 // positive - negative
  // predictive draws (long order of the data file) and per-donkey log-likelihood
  vector[N] y_rep;
  vector[J] log_lik;
  {
    array[J] vector[3] Y_rep = multi_normal_cholesky_rng(mu, L_Sigma);
    for (n in 1:N) y_rep[n] = Y_rep[donkey[n]][cond[n]];
    for (j in 1:J) log_lik[j] = multi_normal_cholesky_lpdf(Y[j] | mu[j], L_Sigma);
  }
}
