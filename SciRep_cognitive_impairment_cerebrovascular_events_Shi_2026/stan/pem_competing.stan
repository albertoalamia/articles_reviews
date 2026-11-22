// E1, E1b, E1c (plan §3, §3b.2, §5): cause-specific piecewise-exponential hazards on the life table that the
// numbers at risk fix. g group (1 NCI, 2 CI), j interval ((0,1] (1,2] (2,3] (3,4] (4,4.2]), k cause (1 stroke,
// 2 death). The same likelihood as the stage 3 glm of R/06_fit_frequentist.R:
//   D[g,j,k] ~ Poisson(PY[g,j] * h[g,j,k]),   log h[g,j,k] = alpha[j,k] + beta[p(j),k] * CI[g]
// split = 0: one group effect per cause, p(j) = 1 (the plan's model, proportional hazards);
// split = 1: the group effect free before and after the last interval, p(j) = 1 for j < J, 2 for j = J
//            (plan §7, S2: the structure that follows the time pattern of the exposed events).
// Switches rewritten by run_model.sh: prior_only (1 skips the likelihood), beta_sd (1; 2 = wide), split.
data {
  int<lower=1> G;
  int<lower=2> J;
  int<lower=1> K;
  array[G, J, K] int<lower=0> D;          // events
  array[G] vector<lower=0>[J] PY;         // person-years
  array[G] int<lower=0, upper=1> CI;      // MMSE < 24
  vector<lower=0>[J] width;               // interval lengths, years
  vector<lower=0>[J] t_end;               // interval ends (not used in the likelihood; kept with the data)
  int<lower=0, upper=1> prior_only;
  real<lower=0> beta_sd;
  int<lower=0, upper=1> split;
}
transformed data {
  int P = split ? 2 : 1;
  array[J] int period;
  for (j in 1:J) period[j] = (split && j == J) ? 2 : 1;
}
parameters {
  matrix[J, K] alpha;                     // log baseline hazard per interval and cause (per person-year)
  matrix[P, K] beta;                      // log hazard ratio CI vs NCI per cause (and per period if split)
}
transformed parameters {
  array[G] matrix[J, K] log_h;
  for (g in 1:G)
    for (j in 1:J)
      log_h[g, j] = alpha[j] + beta[period[j]] * CI[g];
}
model {
  to_vector(alpha) ~ normal(log(0.005), 1.5);
  to_vector(beta) ~ normal(0, beta_sd);
  if (!prior_only)
    for (g in 1:G)
      for (j in 1:J)
        D[g, j] ~ poisson_log(log(PY[g, j]) + log_h[g, j]);
}
generated quantities {
  matrix[P, K] hr = exp(beta);            // E1b (row 1: whole follow-up, or (0, 4] if split; row 2: (4, 4.2])
  array[G] matrix[J, K] F;                // E1: cumulative incidence of cause k by the end of interval j, group g
  vector[K] RD_pre;                       // CI - NCI at the end of interval J - 1 (year 4)
  vector[K] RR_pre;
  vector[K] RD_end;                       // CI - NCI at the end of follow-up (4.2 years)
  vector[K] RR_end;
  matrix[G, K] tail_ratio;                // E1c: hazard in the last interval over the person-time-weighted mean hazard before it
  array[G, J, K] int D_rep;               // predictive cell counts (-1 where the rng would overflow)
  array[G, J, K] real log_lik;
  for (g in 1:G) {
    real S = 1;
    row_vector[K] Fk = rep_row_vector(0, K);
    for (j in 1:J) {
      row_vector[K] h = exp(log_h[g, j]);
      real hd = sum(h);
      Fk += S * h / hd * (-expm1(-hd * width[j]));
      S *= exp(-hd * width[j]);
      F[g, j] = Fk;
      for (k in 1:K) {
        real eta = log(PY[g, j]) + log_h[g, j, k];
        D_rep[g, j, k] = eta < 20 ? poisson_log_rng(eta) : -1;
        log_lik[g, j, k] = poisson_log_lpmf(D[g, j, k] | eta);
      }
    }
    for (k in 1:K)
      tail_ratio[g, k] = exp(log_h[g, J, k])
                         / (dot_product(PY[g, 1:(J - 1)], exp(col(log_h[g], k)[1:(J - 1)])) / sum(PY[g, 1:(J - 1)]));
  }
  for (k in 1:K) {
    RD_pre[k] = F[G, J - 1, k] - F[1, J - 1, k];
    RR_pre[k] = F[G, J - 1, k] / F[1, J - 1, k];
    RD_end[k] = F[G, J, k] - F[1, J, k];
    RR_end[k] = F[G, J, k] / F[1, J, k];
  }
}
