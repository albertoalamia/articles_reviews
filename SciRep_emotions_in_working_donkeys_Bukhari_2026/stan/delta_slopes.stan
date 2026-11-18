// E4 (plan §3): within each treatment t (1 negative, 2 positive), the signed change in RMSSD (ms) on the
// signed change in SBR (blinks/min) or in ET (degC), chosen by the data file (delta_sbr_*.json or
// delta_et_*.json): y ~ Normal(a[t] + b[t] * x, s[t]). No donkey term (one row per donkey and treatment).
// Same likelihood as glmmTMB(dRMSSD ~ treatment * x, dispformula = ~ treatment) in R/02_fit_frequentist.R.
// Priors: plan §5; b_prior_sd comes with the data (3 ms per blink/min, 40 ms per degC: one prior SD at the
// slope where the implied within-treatment correlation reaches 1, section 7, 2026-11-18).
// Derived: b[2] - b[1]; r[t] = b[t] * sd(x_t) / sd(y_t) with the sample SDs, as in stage 3.
data {
  int<lower=1> N;
  array[N] int<lower=1, upper=2> trt;
  vector[N] x;
  vector[N] y;
  int<lower=0, upper=1> prior_only;
  real<lower=0> prior_scale;
  real<lower=0> b_prior_sd;
}
transformed data {
  vector[2] sd_x;
  vector[2] sd_y;
  for (t in 1:2) {
    int n_t = 0;
    for (n in 1:N) n_t += (trt[n] == t);
    vector[n_t] xt;
    vector[n_t] yt;
    int k = 0;
    for (n in 1:N) if (trt[n] == t) { k += 1; xt[k] = x[n]; yt[k] = y[n]; }
    sd_x[t] = sd(xt);
    sd_y[t] = sd(yt);
  }
}
parameters {
  vector[2] a;
  vector[2] b;
  vector<lower=0>[2] s;
}
model {
  a ~ normal(0, 50 * prior_scale);
  b ~ normal(0, b_prior_sd * prior_scale);
  s ~ normal(0, 50 * prior_scale);
  if (!prior_only) y ~ normal(a[trt] + b[trt] .* x, s[trt]);
}
generated quantities {
  real b_diff = b[2] - b[1];                            // positive - negative
  vector[2] r = b .* sd_x ./ sd_y;                      // slope-implied within-treatment correlation
  vector[N] y_rep = to_vector(normal_rng(a[trt] + b[trt] .* x, s[trt]));
  vector[N] log_lik;
  for (n in 1:N) log_lik[n] = normal_lpdf(y[n] | a[trt[n]] + b[trt[n]] * x[n], s[trt[n]]);
}
