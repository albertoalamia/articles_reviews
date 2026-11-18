// SBR, planned model (plan §3, v1.1): blinks/min ~ NegBinomial2(mu, phi), log mu = eta,
// eta = b0 + b_cond[c] + b_ord[o] + u[donkey], u ~ Normal(0, tau), non-centred.
// Same likelihood and structure as glmmTMB(y ~ condition + order + (1 | donkey), family = nbinom2)
// in R/02_fit_frequentist.R. Priors: plan §5. Coding (R/01_prepare_data.R): cond 1 control,
// 2 positive, 3 negative; ord 1..3 = position in the sequence.
// Data switches: prior_only (1 = prior predictive, likelihood skipped); prior_scale (sensitivities
// i, i': every prior SD multiplied by it).
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
  vector[2] b_cond;            // positive - control, negative - control (log rate ratios)
  vector[2] b_ord;             // position 2 - 1, position 3 - 1
  real<lower=0> tau;           // between-donkey SD on the log scale
  vector[J] z;
  real<lower=0> inv_sqrt_phi;  // 1 / sqrt(phi): half-normal prior (plan §5)
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[J] u = tau * z;
  real phi = inv_square(inv_sqrt_phi);
  vector[N] eta = b0 + bc[cond] + bo[ord] + u[donkey];
}
model {
  b0 ~ normal(log(20), 1 * prior_scale);
  b_cond ~ normal(0, 1 * prior_scale);
  b_ord ~ normal(0, 1 * prior_scale);
  tau ~ normal(0, 1 * prior_scale);
  inv_sqrt_phi ~ normal(0, 1 * prior_scale);
  z ~ std_normal();
  if (!prior_only) y ~ neg_binomial_2_log(eta, phi);
}
generated quantities {
  // condition values for a typical donkey (u = 0), averaged over the three order positions
  vector[3] eta_c = b0 + bc + mean(bo);
  vector[3] mu_c = exp(eta_c);                          // blinks/min at u = 0 (the glmmTMB/emmeans scale)
  vector[3] mu_c_marg = mu_c * exp(square(tau) / 2);    // averaged over donkeys
  // E1, E2: rate ratios and differences
  real rr_pos = exp(b_cond[1]);
  real rr_neg = exp(b_cond[2]);
  real rr_pos_neg = exp(b_cond[1] - b_cond[2]);
  real diff_pos = mu_c[2] - mu_c[1];
  real diff_neg = mu_c[3] - mu_c[1];
  real diff_pos_neg = mu_c[2] - mu_c[3];
  real diff_pos_marg = mu_c_marg[2] - mu_c_marg[1];
  real diff_neg_marg = mu_c_marg[3] - mu_c_marg[1];
  real diff_pos_neg_marg = mu_c_marg[2] - mu_c_marg[3];
  // E3: latent-scale ICC, sigma2_latent = trigamma(phi) + 1 / mu_control (plan §3)
  real sigma2_latent = trigamma(phi) + 1 / mu_c[1];
  real icc = square(tau) / (square(tau) + sigma2_latent);
  // predictive draws and pointwise log-likelihood
  array[N] int y_rep;
  vector[N] log_lik;
  for (n in 1:N) {
    // eta >= 20 (mu >= 4.9e8, only reachable under widened priors without data) would overflow the rng:
    // such cells are marked -1 and dropped by R/03_postprocess.R, which reports their share
    y_rep[n] = eta[n] < 20 ? neg_binomial_2_log_rng(eta[n], phi) : -1;
    log_lik[n] = neg_binomial_2_log_lpmf(y[n] | eta[n], phi);
  }
}
