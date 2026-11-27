# Data request — DRAFT (not sent)

To: {han}
Subject: Data request — Shi et al. 2026, Sci Rep, "Baseline cognitive impairment predicts cerebrovascular events in stroke-free Chinese adults"

---

Dear Professor Han,

I am a psychiatrist and biostatistician based in Italy. I read with interest your recent paper
in Scientific Reports on baseline cognitive impairment and cerebrovascular events in the APAC
cohort (doi 10.1038/s41598-026-78298-4). Whether a screening score such as the MMSE carries
prognostic information for stroke in people without a history of it is a question of direct
relevance to my clinical work, and a community cohort of this size with vascular imaging is a
rare resource for answering it.

I am writing to ask whether you would be willing to share the data underlying the paper, as your
data availability statement indicates. My aim is a methodological re-analysis: I would like to
reproduce the Cox models and the Kaplan–Meier curves as reported, and to fit alongside them
models that treat death as a competing event, use the continuous MMSE score and age as the time
scale, and quantify what the MMSE adds to age alone for identifying future stroke, in both a
frequentist and a Bayesian framework. I should say openly that I intend to publish the result as
a methodological commentary. Should it come to that, you would receive the full text before
anything is made public, and your response would be published together with it.

I should also mention why the individual data would be particularly helpful. While reading the
paper I could not reconcile some of the reported elements with one another: the curves in
Figure 2 with the event counts and numbers at risk in Table 2; the median follow-up of 4.1 years
with a cognitive assessment in 2012–2013 and an end of follow-up on 31 December 2015; and the
P value of 0.0005 for manual workers in Table 1 with the two percentages in that row. Access to
the data would allow me to establish whether this reflects an aspect of the analysis I have
misunderstood, which is entirely possible, rather than an issue in the reporting.

Concretely, the following would be ideal, in any format you find convenient (CSV, Excel, SAS or
R files):

1. One record per participant of the 3,875 analysed: MMSE total score and date of the
   assessment; date of the APAC baseline examination; the covariates used in the models (age,
   sex, education, occupation, hypertension, homocysteine, intracranial stenosis) with the date
   of the visit each comes from; the other Table 1 variables if convenient.
2. For each participant: date and type of first stroke (ischaemic, intracerebral haemorrhage,
   subarachnoid haemorrhage), date of death, date of last contact or censoring, and the source
   of ascertainment (interview, death certificate, hospital record).
3. The SAS programs used for Table 1, Table 2 and Figure 2, or failing that the output listings,
   and the dataset from which Figure 2 was drawn.
4. If possible, the same variables for the 1,565 excluded participants (Supplementary Table S1),
   so that the selection can be modelled.

I would of course acknowledge your contribution and respect any conditions you wish to attach to
the use of the data. In return, I will share with you the full analysis before anyone else: all
code, the processed data and step-by-step instructions, in a pinned software environment, so that
every result can be reproduced on your side from start to finish.

For transparency, I should add that if I receive no reply within three weeks, or if sharing the
data is not possible, I will proceed with the commentary on the summary statistics reported in
the paper and publish it without further notice. In that case too the commentary, with all code
and instructions, will be freely available on my site so that it can be checked and challenged by
anyone, yourselves first of all.

Thank you for considering this request.

With kind regards,

Alberto Alamia, MD
Psychiatrist, biostatistician
telepsichiatria.org
alberto.alamia@telepsichiatria.org

---

## Notes for sending
- Only one address is printed in the paper (Han, 126.com). Consider adding the APAC coordinating
  centre once an address is found (Beijing Tiantan Hospital, Wang / Meng / Tian).
- Three-week window from the sending date; publication proceeds after it as the letter states.
- When sent: add a row to `contacts.md` → Log, rename this file `_DRAFT` → `_SENT`
  (`tools/send_email.py` does both and appends the `Sent:` line).

Sent: 2026-11-20T23:19+01:00  gmail-id 1a1fb0abb9f366c4
