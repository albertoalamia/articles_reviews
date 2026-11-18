// SBR, sensitivity (iii) (plan §5): Poisson instead of NB2, the limit phi -> infinity; otherwise
// identical to sbr_nb2.stan (same coding, priors and switches). Stage 3 reports this model when phi
// is not identified (non-PD Hessian or phi > 1e3), which happened in 50-100 % of replicates (S3).
data {
  int<lower=1> N;
  int<lower=1> J;
  array[N] int<lower=1, upper=J> donkey;
  array[N] int<lower=1, upper=3> cond;
  array[N] int<lower=1, upper=3> ord;
  array[N] int<lower=0> y;
  int<lower=0, upper=1> prior_only;
  real<lower=0> prior_scale;
}
parameters {
  real b0;
  vector[2] b_cond;
  vector[2] b_ord;
  real<lower=0> tau;
  vector[J] z;
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[J] u = tau * z;
  vector[N] eta = b0 + bc[cond] + bo[ord] + u[donkey];
}
model {
  b0 ~ normal(log(20), 1 * prior_scale);
  b_cond ~ normal(0, 1 * prior_scale);
  b_ord ~ normal(0, 1 * prior_scale);
  tau ~ normal(0, 1 * prior_scale);
  z ~ std_normal();
  if (!prior_only) y ~ poisson_log(eta);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);
  vector[3] mu_c = exp(eta_c);
  vector[3] mu_c_marg = mu_c * exp(square(tau) / 2);
  real rr_pos = exp(b_cond[1]);
  real rr_neg = exp(b_cond[2]);
  real rr_pos_neg = exp(b_cond[1] - b_cond[2]);
  real diff_pos = mu_c[2] - mu_c[1];
  real diff_neg = mu_c[3] - mu_c[1];
  real diff_pos_neg = mu_c[2] - mu_c[3];
  real diff_pos_marg = mu_c_marg[2] - mu_c_marg[1];
  real diff_neg_marg = mu_c_marg[3] - mu_c_marg[1];
  real diff_pos_neg_marg = mu_c_marg[2] - mu_c_marg[3];
  real sigma2_latent = 1 / mu_c[1];                      // Poisson limit of trigamma(phi) + 1 / mu
  real icc = square(tau) / (square(tau) + sigma2_latent);
  array[N] int y_rep;
  vector[N] log_lik;
  for (n in 1:N) {
    y_rep[n] = eta[n] < 20 ? poisson_log_rng(eta[n]) : -1;
    log_lik[n] = poisson_log_lpmf(y[n] | eta[n]);
  }
}
