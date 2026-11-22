// E2, E3 (plan §3, §3b.2, §5): the exposure effect given an age effect, on the calibrated population (A6).
// i person (3,875), g group (1 NCI, 2 CI). The same likelihood as fit_e2() of R/06_fit_frequentist.R:
//   mu[i] = 1 - exp(-tau * lambda0 * exp(b_ci CI[i] + b_age a[i] + b_male male[i])),   D[g] ~ Poisson(sum_{i in g} mu[i])
// with a[i] = (age[i] - age_ref) / 10, so exp(b_age) = theta_age is the hazard multiplier per decade.
// Stage 3 fixes (b_age, b_male); here they are parameters with priors. Two counts and four parameters: b_age is
// not identified by the data, by construction (plan §2); its posterior is its prior, and b_ci follows it.
// Switches rewritten by run_model.sh: prior_only (1 skips the likelihood), prior (1 P1 "as Model 1 implies",
// 2 P2 "as population studies report", 3 P3 "unknown between 1 and 3"), age_max (ceiling of A6: 90; 80, 100).
functions {
  // expected concordance of the ranking `score` when person i is a case with probability risk[i]:
  //   sum_{i != j} r_i (1 - r_j) [1(s_i > s_j) + 1/2 1(s_i = s_j)] / sum_{i != j} r_i (1 - r_j)
  // (c_expected() of R/06_fit_frequentist.R; ties in the score count one half)
  real c_expected(vector score, vector risk) {
    int n = rows(score);
    array[n] int o = sort_indices_asc(score);
    real num = 0;
    real before = 0;                      // sum of (1 - r) over strictly lower scores
    int i = 1;
    while (i <= n) {
      real q_grp = 0;
      real r_grp = 0;
      real rq_grp = 0;
      int j = i;
      while (j <= n) {
        if (score[o[j]] != score[o[i]]) break;
        q_grp += 1 - risk[o[j]];
        r_grp += risk[o[j]];
        rq_grp += risk[o[j]] * (1 - risk[o[j]]);
        j += 1;
      }
      num += r_grp * before + 0.5 * (r_grp * q_grp - rq_grp);
      before += q_grp;
      i = j;
    }
    return num / (sum(risk) * sum(1 - risk) - dot_product(risk, 1 - risk));
  }
}
data {
  int<lower=1> N;
  array[N] int<lower=0, upper=1> CI;      // MMSE < 24
  array[N] int<lower=0, upper=1> male;
  vector[N] age_90;                       // years, A6 with the ceiling at 90 (main), 80, 100
  vector[N] age_80;
  vector[N] age_100;
  int<lower=80, upper=100> age_max;
  real age_ref;                           // 50
  real age_flag;                          // 65, the age rule of E3c
  array[2] int<lower=0> D;                // events: NCI, CI
  real<lower=0> tau;                      // 4.1 years, the median follow-up
  real<lower=0> t_pred;                   // 4.2 years, horizon of the risks in E3
  int<lower=1, upper=3> prior;
  int<lower=0, upper=1> prior_only;
}
transformed data {
  vector[N] age = age_max == 90 ? age_90 : (age_max == 80 ? age_80 : age_100);
  vector[N] a = (age - age_ref) / 10;     // decades from age_ref
  vector[N] ci = to_vector(CI);
  vector[N] m = to_vector(male);
  int n1 = sum(CI);
  array[n1] int idx1;                     // the CI group
  array[N - n1] int idx0;                 // the NCI group
  array[N] int flag_age;
  array[N] int flag_either;
  {
    int p0 = 0;
    int p1 = 0;
    for (i in 1:N) {
      if (CI[i] == 1) { p1 += 1; idx1[p1] = i; } else { p0 += 1; idx0[p0] = i; }
      flag_age[i] = age[i] >= age_flag;
      flag_either[i] = (CI[i] == 1 || age[i] >= age_flag);
    }
  }
  if (age_max != 90 && age_max != 80 && age_max != 100) reject("age_max must be 80, 90 or 100");
}
parameters {
  real<lower=0> lambda0;                  // hazard per person-year of a woman aged age_ref with MMSE >= 24
  real b_ci;                              // log hazard ratio, MMSE < 24, at given age and sex
  real<lower=(prior == 3 ? 0 : negative_infinity()), upper=(prior == 3 ? log(3) : positive_infinity())> b_age;   // per decade
  real b_male;
}
transformed parameters {
  vector[N] mu = -expm1(-tau * lambda0 * exp(b_ci * ci + b_age * a + b_male * m));   // P(event within tau)
  vector[2] E = [sum(mu[idx0]), sum(mu[idx1])]';
}
model {
  lambda0 ~ lognormal(log(0.004), 1.5);
  b_ci ~ normal(0, 1);
  b_male ~ normal(log(1.3), 0.15);
  if (prior == 1) b_age ~ normal(log(1.55), 0.10);
  else if (prior == 2) b_age ~ normal(log(2), 0.15);
  else b_age ~ uniform(0, log(3));
  if (!prior_only) D ~ poisson(E);
}
generated quantities {
  real hr_ci = exp(b_ci);                 // E2
  real theta_age = exp(b_age);
  real theta_male = exp(b_male);
  real age_equiv_years = 10 * b_ci / b_age;   // E3a
  real c_age_sex;                         // E3b
  real c_with_mmse;
  real c_gain;
  vector[3] sens;                         // E3c; rules: 1 MMSE < 24, 2 age >= age_flag, 3 either
  vector[3] spec;
  vector[3] ppv;
  vector[3] npv;
  array[2] int D_rep;                     // -1 where the rng would overflow
  vector[2] log_lik;
  {
    vector[N] lp0 = b_age * a + b_male * m;
    vector[N] risk = -expm1(-t_pred * lambda0 * exp(b_ci * ci + lp0));
    real tot = sum(risk);
    c_age_sex = c_expected(lp0, risk);
    c_with_mmse = c_expected(b_ci * ci + lp0, risk);
    c_gain = c_with_mmse - c_age_sex;
    for (r in 1:3) {
      real tp = 0;                        // expected cases among the flagged
      real nf = 0;                        // number flagged
      for (i in 1:N) {
        int f = r == 1 ? CI[i] : (r == 2 ? flag_age[i] : flag_either[i]);
        if (f) { tp += risk[i]; nf += 1; }
      }
      sens[r] = tp / tot;
      spec[r] = ((N - nf) - (tot - tp)) / (N - tot);
      ppv[r] = tp / nf;
      npv[r] = ((N - nf) - (tot - tp)) / (N - nf);
    }
  }
  for (g in 1:2) {
    D_rep[g] = E[g] < 1e8 ? poisson_rng(E[g]) : -1;
    log_lik[g] = poisson_lpmf(D[g] | E[g]);
  }
}
