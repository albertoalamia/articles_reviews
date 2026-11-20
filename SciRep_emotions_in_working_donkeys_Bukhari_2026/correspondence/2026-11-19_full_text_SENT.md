# Full text of the commentary, for the authors' reply — DRAFT (not sent)

To: rebecca.sv.parkes@hkjc.org.hk, habukhari2-c@my.cityu.edu.hk
Cc: alan.mcelligott@cityu.edu.hk, pmortens@cityu.edu.hk
Subject: Re: Data request — Bukhari et al. 2026, Sci Rep — full text of the commentary, for your reply

---

Dear Dr Parkes, Dear Dr Bukhari,

As promised, here is the full text of the commentary before anything is made public. Two PDF
files are attached: the technical review, which is the document of record, and a short
plain-language companion for readers without a statistical background. Both are drafts; both
carry today's date; and both will be updated in two ways before publication: with your reply, and
with your data if they arrive, in which case every analysis is rerun on them and the
reconstruction described in the review becomes a check rather than the basis.

The review is long, so let me state its substance in a few lines, so that you can see at once
what it rests on.

1. The six changes in Table 2 (control minus positive, control minus negative) are all printed
   as positive numbers. By the stated definition five of them should be negative, and the four
   printed means for ET and RMSSD lie outside the range the condition means allow. The values
   reproduce exactly as the mean absolute per-donkey change, and the regressions of Tables 3–4
   reproduce from those unsigned values. My reading is therefore that the changes were analysed
   without their sign; I would be glad to be corrected.
2. Two of the six p-values, p = 0.002 for SBR under the positive treatment and p = 0.005 for
   RMSSD under the positive treatment, are not consistent with the means and standard deviations
   of Table 2 or with the per-donkey changes in Figures 3 and 4: those give paired t statistics
   of about 17 and 8, where the reported p-values would need about 3.4 and 3.0. I cannot tell
   from the paper which analysis produced them.
3. The Discussion states that RMSSD decreased under the negative treatment, "consistent with
   previous studies in horses". Table 2 and Figure 2 report an increase, from 47.26 to 57.35 ms.
4. The positive and negative treatments were each compared with the control but never with each
   other. For ET and RMSSD both treatments moved the measure in the same direction, so the data as
   reported do not support these two measures as markers of valence. SBR is the exception: it
   moved in opposite directions, and the re-analysis confirms a clear group-level difference in
   both directions.
5. The re-analysis (negative-binomial and multivariate mixed models, fitted with glmmTMB and in
   Stan, on 200 datasets reconstructed from the figures and the tables) agrees with the paper on
   SBR, finds that the relation between ΔRMSSD and ΔSBR has opposite signs under the two
   treatments, and estimates how well a single blink count separates the conditions for one
   donkey: very well for lucerne against clippers, moderately for clippers against the control.

Points 1 to 4 follow from the published numbers alone; the review marks each statement as
"confirmed", "inferred" or "needs data" and says which assumption every inferred statement
depends on. The entire chain, from the transcribed tables to every figure in the text, is code in
a public repository (https://github.com/albertoalamia/articles_reviews, folder
SciRep_emotions_in_working_donkeys_Bukhari_2026), with a pinned software environment; the
posterior draws (7 GB) are available on request.

The section "What would settle the open points" lists what your data would resolve, and these
three items are the ones that matter most: the per-donkey values of the three measures in each
condition with the sign of each change, the order of conditions per donkey, and the analysis
output behind the six p-values.

On timing. I intend to publish on or after 11 December 2026, three weeks from today. Your reply,
in whatever form and length you choose, will be published with the review in full and unedited;
a reply that arrives later will be added when it arrives. If you need more time, please say so
and I will wait. If the data reach me before publication, the review you see published will be
the one computed on them.

If anything in the review is factually wrong about the study, its procedures or its analysis, I
would be grateful to hear it: that is exactly the kind of error I would prefer to correct before
publication rather than after.

With kind regards,

Alberto Alamia, MD
Psychiatrist, biostatistician
telepsichiatria.org
alberto.alamia@telepsichiatria.org

---

## Notes for sending (not sent)

- Send from the repo root with both PDFs attached, after checking the dry run:

      python3 tools/send_email.py SciRep_emotions_in_working_donkeys_Bukhari_2026/correspondence/2026-11-19_full_text_DRAFT.md \
        --attach _site/SciRep_emotions_in_working_donkeys_Bukhari_2026/review.pdf \
        --attach _site/SciRep_emotions_in_working_donkeys_Bukhari_2026/primer.pdf --dry-run

  then the same command without `--dry-run`. The PDFs in `_site/` were rendered from the source
  committed in 5044f8f; render again first if the source changes.
- The publication date in the text is three weeks from 2026-11-20; adjust the date and the
  file name if the message goes out on another day.
- Answers Parkes's message of 2026-11-09 (Gmail-id 1a1bf29873a8a6ab, thread 1a1748c4d68d2a1a);
  send_email.py sets no In-Reply-To header, so the subject carries the thread.
- After sending: add a row to `contacts.md` → Log; replace the TODO comment in the Right of
  reply section of `review.qmd` with the send date; commit the renamed `_SENT.md`.

Sent: 2026-11-19T22:36+01:00  gmail-id 1a1f5bcf61fa88a2
