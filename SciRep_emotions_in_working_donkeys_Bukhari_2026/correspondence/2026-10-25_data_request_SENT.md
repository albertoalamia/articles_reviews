# Data request — DRAFT (not sent)

To: habukhari2-c@my.cityu.edu.hk, rebecca.sv.parkes@hkjc.org.hk
Cc: alan.mcelligott@cityu.edu.hk, pmortens@cityu.edu.hk  (optional)
Subject: Data request — Bukhari et al. 2026, Sci Rep, "Heart rate variability, eye temperature, and spontaneous blink rates as measures of emotions in working donkeys"

---

Dear Dr Bukhari, Dear Dr Parkes,

I am a psychiatrist and biostatistician based in Italy, and I work on donkey-assisted
interventions in mental health. I read with great interest your recent paper in Scientific
Reports on blink rate, eye temperature and heart rate variability as measures of emotion in
working donkeys (doi 10.1038/s41598-026-62753-3). Physiological indicators of affective state in
donkeys are directly relevant to my own work, and yours is, as you note, the first dataset of its
kind.

I am writing to ask whether you would be willing to share the data underlying the paper, as
indicated in your data availability statement. My aim is a methodological re-analysis: I would
like to reproduce the reported analyses and to fit, alongside them, mixed models that treat blink
rate as a count outcome and account for treatment order and ambient conditions, in both a
frequentist and a Bayesian framework. I should say openly that I intend to publish the result as
a methodological commentary. Should it come to that, you would receive the full text before
anything is made public, and your response would be published together with it.

I should also mention why the raw data would be particularly helpful. While reading the paper I
could not reconcile some of the summary statistics with one another, for instance the reported
mean changes and their p-values against the condition means and standard deviations in Table 2.
Access to the per-animal values would allow me to establish whether this reflects an aspect of the
analysis I have misunderstood, which is entirely possible, rather than an issue in the reporting.

Concretely, the following would be ideal, in any format you find convenient (CSV, Excel, R or
SPSS files):

1. Per donkey and per treatment (control, positive, negative): spontaneous blink rate as counted
   by each coder, maximum medial-canthus eye temperature, RMSSD, and the 3-minute window times.
2. For each donkey: the order in which the three treatments were applied, time of day of each
   recording, and ambient temperature, humidity and wind speed at the time of recording.
3. Donkey-level covariates used or collected: age, sex, body condition score, working status.
4. If available, the HRV export or Kubios reports (mean heart rate, percentage of corrected beats
   per window) and the analysis script or the software output for the linear models reported in
   the Results.

I would of course acknowledge your contribution and respect any conditions you wish to attach to
the use of the data. In return, I will share with you the full analysis before anyone else: all
code, the Stan models, the processed data and step-by-step instructions, in a pinned software
environment, so that every result can be reproduced on your side from start to finish.

For transparency, I should add that if I receive no reply, or if sharing the data is not
possible, I will proceed with the re-analysis on the summary statistics reported in the paper and
publish it without further notice. In that case too the commentary, with all code, data and
instructions, will be freely available on my site so that it can be checked and challenged by
anyone, yourselves first of all.

Thank you for considering this request, and congratulations on opening this line of research.

With kind regards,

Alberto Alamia, MD
Psychiatrist, biostatistician
telepsichiatria.org
alberto.alamia@telepsichiatria.org

---

## Notes for sending
- Paper quotes "available from the corresponding author on reasonable request" (fulltext ll. 1029–1034).
- Send from the telepsichiatria.org address so the signature and sender match.
- When sent: add a row to `contacts.md` → Log, rename this file dropping `_DRAFT`, and save the
  sent version verbatim. Set a reminder for a follow-up after 3 weeks if no reply.

Sent: 2026-10-25T20:31+01:00  gmail-id 1a1748c4d68d2a1a
