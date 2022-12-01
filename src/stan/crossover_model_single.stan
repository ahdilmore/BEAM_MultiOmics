data {
  int<lower=0> N;                        // Number of samples
  int<lower=0> p;                        // Number of covariates
  int<lower=0> S;                        // Number of subjects
  real depth[N];                         // log sequencing depths
  matrix[N, p] x;                        // Fixed-effect design matrix
  int y[N];                              // Counts per sample
  int<lower=1, upper=S> subject_map[N];  // Mapping of sample
  real<lower=0> B_p;                     // Normal stdev prior for beta_var
  real<lower=0> phi_s;                   // Cauchy scale prior for phi
  real<lower=0> u_p;                     // Normal stdev prior for subject
}

parameters {
  vector[p] beta_var;
  real reciprocal_phi;
  vector[S] subject_int;
}

model {
  vector[N] lam;

  reciprocal_phi ~ cauchy(0, phi_s);
  beta_var[1] ~ normal(-5.5, B_p);
  for (j in 2:p) {
    beta_var[j] ~ normal(0, B_p);
  }
  subject_int ~ normal(0, u_p);

  lam = x * beta_var;
  for (n in 1:N) {
    lam[n] = lam[n] + subject_int[subject_map[n]];
  }

  y ~ neg_binomial_2_log(lam + to_vector(depth), 1/reciprocal_phi);
}

generated quantities {
  vector[N] log_lhood;
  vector[N] y_predict;
  vector[N] lam_new;

  lam_new = x * beta_var;

  for (n in 1:N) {
    lam_new[n] = lam_new[n] + subject_int[subject_map[n]];
    y_predict[n] = neg_binomial_2_log_rng(depth[n] + lam_new[n], 1/reciprocal_phi);
    log_lhood[n] = neg_binomial_2_log_lpmf(y[n] | depth[n] + lam_new[n], 1/reciprocal_phi);
  }
}
