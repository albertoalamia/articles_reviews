// ET, sensitivity (ii') (plan §5): the v1.0 primary. Shared donkey intercept u ~ Normal(0, tau) and a
// condition-specific residual SD: y ~ Normal(b0 + b_cond[c] + b_ord[o] + u[donkey], sigma[c]).
// Same likelihood as glmmTMB(y ~ condition + order + (1 | donkey), dispformula = ~ condition).
// Nested in et_mvn.stan: equal correlations tau^2 / (tau^2 + sigma_c sigma_c') between conditions.
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
parameters {
  real b0;
  vector[2] b_cond;
  vector[2] b_ord;
  real<lower=0> tau;
  vector[J] z;
  vector<lower=0>[pooled ? 1 : 3] sigma_raw;
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[3] sigma = pooled ? rep_vector(sigma_raw[1], 3) : sigma_raw;
  vector[J] u = tau * z;
  vector[N] eta = b0 + bc[cond] + bo[ord] + u[donkey];
}
model {
  b0 ~ normal(35, 2 * prior_scale);
  b_cond ~ normal(0, 2 * prior_scale);
  b_ord ~ normal(0, 2 * prior_scale);
  tau ~ normal(0, 2 * prior_scale);
  sigma_raw ~ normal(0, 2 * prior_scale);
  z ~ std_normal();
  if (!prior_only) y ~ normal(eta, sigma[cond]);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);
  real diff_pos = b_cond[1];
  real diff_neg = b_cond[2];
  real diff_pos_neg = b_cond[1] - b_cond[2];
  // E3 in the shared-intercept parameterisation: tau and the per-condition ICC
  vector[3] icc = square(tau) ./ (square(tau) + square(sigma));
  vector[N] y_rep = to_vector(normal_rng(eta, sigma[cond]));
  vector[N] log_lik;
  for (n in 1:N) log_lik[n] = normal_lpdf(y[n] | eta[n], sigma[cond[n]]);
}
