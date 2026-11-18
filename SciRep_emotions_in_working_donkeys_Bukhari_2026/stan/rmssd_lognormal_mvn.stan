// RMSSD, planned model (plan §3, v1.1): log-normal MVN. (log y_i1, log y_i2, log y_i3) ~ MVN(mu_i, Sigma),
// mu_ic = b0 + b_cond[c] + b_ord[o(i, c)], Sigma = diag(sigma) Omega diag(sigma) unstructured, sigma on
// the log scale. Same likelihood as glmmTMB(log(y) ~ condition + order + us(0 + condition | donkey),
// dispformula = ~ 0). As in et_mvn.stan the donkey vector is integrated out. Priors: plan §5.
// Estimands (plan §1, §3): ratio of arithmetic means exp(delta_beta + (sigma_c^2 - sigma_ref^2) / 2)
// primary, median-donkey ratio exp(delta_beta) alongside; differences in ms from exp(eta_c + sigma_c^2 / 2).
// Coding: cond 1 control, 2 positive, 3 negative; ord 1..3. Switches: prior_only, prior_scale, pooled.
data {
  int<lower=1> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> donkey;
  array[N] int<lower=1, upper=3> cond;
  array[N] int<lower=1, upper=3> ord;
  vector<lower=0>[N] y;
  int<lower=0, upper=1> prior_only;
  real<lower=0> prior_scale;
  int<lower=0, upper=1> pooled;
}
transformed data {
  array[J] vector[3] Y;                      // log RMSSD
  array[J, 3] int ord_jc;
  array[J, 3] int seen = rep_array(0, J, 3);
  for (n in 1:N) {
    Y[donkey[n]][cond[n]] = log(y[n]);
    ord_jc[donkey[n], cond[n]] = ord[n];
    seen[donkey[n], cond[n]] += 1;
  }
  for (j in 1:J) for (c in 1:3)
    if (seen[j, c] != 1) reject("donkey ", j, ", condition ", c, ": ", seen[j, c], " rows; exactly one required");
}
parameters {
  real b0;
  vector[2] b_cond;                          // median-donkey log ratios: positive / control, negative / control
  vector[2] b_ord;
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
  b0 ~ normal(log(50), 1 * prior_scale);
  b_cond ~ normal(0, 1 * prior_scale);
  b_ord ~ normal(0, 1 * prior_scale);
  sigma_raw ~ normal(0, 1 * prior_scale);
  L_Omega ~ lkj_corr_cholesky(2);
  if (!prior_only) Y ~ multi_normal_cholesky(mu, L_Sigma);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);                 // log scale, typical donkey, averaged over order
  vector[3] med_c = exp(eta_c);                         // median-donkey RMSSD (ms) per condition
  vector[3] m_c = exp(eta_c + square(sigma) / 2);       // arithmetic means (ms) averaged over donkeys
  // E1, E2 on the link scale (median-donkey log ratios) and as median-donkey ratios
  real lr_pos = b_cond[1];
  real lr_neg = b_cond[2];
  real lr_pos_neg = b_cond[1] - b_cond[2];
  real ratio_med_pos = exp(lr_pos);
  real ratio_med_neg = exp(lr_neg);
  real ratio_med_pos_neg = exp(lr_pos_neg);
  // E1, E2 primary: ratios of arithmetic means, and the differences in ms
  real ratio_pos = exp(lr_pos + (square(sigma[2]) - square(sigma[1])) / 2);
  real ratio_neg = exp(lr_neg + (square(sigma[3]) - square(sigma[1])) / 2);
  real ratio_pos_neg = exp(lr_pos_neg + (square(sigma[2]) - square(sigma[3])) / 2);
  real diff_pos = m_c[2] - m_c[1];
  real diff_neg = m_c[3] - m_c[1];
  real diff_pos_neg = m_c[2] - m_c[3];
  // E3
  matrix[3, 3] Omega = multiply_lower_tri_self_transpose(L_Omega);
  real rho_cp = Omega[1, 2];
  real rho_cn = Omega[1, 3];
  real rho_pn = Omega[2, 3];
  // predictive draws on the ms scale; per-donkey log-likelihood of y (Jacobian -sum(log y) included,
  // so that it is comparable with the stage 3 AICc, which adds 2 * sum(log y))
  vector[N] y_rep;
  vector[J] log_lik;
  {
    array[J] vector[3] Y_rep = multi_normal_cholesky_rng(mu, L_Sigma);
    for (n in 1:N) y_rep[n] = exp(Y_rep[donkey[n]][cond[n]]);
    for (j in 1:J) log_lik[j] = multi_normal_cholesky_lpdf(Y[j] | mu[j], L_Sigma) - sum(Y[j]);
  }
}
