// RMSSD, sensitivity (ii) (plan §5): the v1.0 primary. Gamma with log link, shared donkey intercept and
// a condition-specific shape alpha_c: y ~ Gamma(alpha[c], alpha[c] / mu), log mu = b0 + b_cond[c] +
// b_ord[o] + u[donkey], u ~ Normal(0, tau). Same likelihood as glmmTMB(y ~ condition + order +
// (1 | donkey), family = Gamma(link = "log"), dispformula = ~ condition). Under a shared intercept the
// ratio of arithmetic means equals the median-donkey ratio exp(delta_beta). Priors: plan §5
// (alpha_c ~ Gamma(2, 0.1); prior_scale divides the rate, which multiplies mean and SD of the prior).
// Switches: prior_only, prior_scale, pooled (one alpha).
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
parameters {
  real b0;
  vector[2] b_cond;
  vector[2] b_ord;
  real<lower=0> tau;
  vector[J] z;
  vector<lower=0>[pooled ? 1 : 3] alpha_raw;
}
transformed parameters {
  vector[3] bc = append_row(0, b_cond);
  vector[3] bo = append_row(0, b_ord);
  vector[3] alpha = pooled ? rep_vector(alpha_raw[1], 3) : alpha_raw;
  vector[J] u = tau * z;
  vector[N] eta = b0 + bc[cond] + bo[ord] + u[donkey];
  vector[N] mu = exp(eta);
}
model {
  b0 ~ normal(log(50), 1 * prior_scale);
  b_cond ~ normal(0, 1 * prior_scale);
  b_ord ~ normal(0, 1 * prior_scale);
  tau ~ normal(0, 1 * prior_scale);
  alpha_raw ~ gamma(2, 0.1 / prior_scale);
  z ~ std_normal();
  if (!prior_only) y ~ gamma(alpha[cond], alpha[cond] ./ mu);
}
generated quantities {
  vector[3] eta_c = b0 + bc + mean(bo);
  vector[3] mu_c = exp(eta_c);                          // typical donkey (ms)
  vector[3] m_c = mu_c * exp(square(tau) / 2);          // arithmetic means averaged over donkeys (ms)
  real lr_pos = b_cond[1];
  real lr_neg = b_cond[2];
  real lr_pos_neg = b_cond[1] - b_cond[2];
  real ratio_pos = exp(lr_pos);                         // = ratio of arithmetic means under a shared intercept
  real ratio_neg = exp(lr_neg);
  real ratio_pos_neg = exp(lr_pos_neg);
  real diff_pos = m_c[2] - m_c[1];
  real diff_neg = m_c[3] - m_c[1];
  real diff_pos_neg = m_c[2] - m_c[3];
  vector[3] cv = inv_sqrt(alpha);                       // coefficient of variation per condition
  vector[3] icc = square(tau) ./ (square(tau) + trigamma(alpha));   // log-scale ICC per condition
  vector[N] y_rep = to_vector(gamma_rng(alpha[cond], alpha[cond] ./ mu));
  vector[N] log_lik;
  for (n in 1:N) log_lik[n] = gamma_lpdf(y[n] | alpha[cond[n]], alpha[cond[n]] / mu[n]);
}
