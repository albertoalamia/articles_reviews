pdf

Review this article
Surfacing confounds in measurement methods and blinding gaps
Review: Bukhari et al., Sci Rep 2026 (donkey SBR / ET / RMSSD)

Verdict: A useful first dataset in an understudied species, but the analysis has internal inconsistencies serious enough that the main conclusions don’t follow from the data as reported. I’d call it major revision, bordering on reject-and-resubmit.
Critical issues

1. The “change” scores appear to be absolute values, so their sign is lost.
Methods define change as control minus treatment, which should give negative values for positive-SBR (+19), for ET in both arms, and for RMSSD in both arms. Instead every Δ in Table 2 and Figs 3–4 is ≥0. The mean changes also don’t match the differences of the means. For RMSSD under the negative treatment, the means differ by 10.09 but the reported mean change is 10.73. For RMSSD under the positive treatment, the means differ by 32.97 but the reported mean change is 37.73. That pattern is what you get from |Δ|. With unsigned deltas, the ΔRMSSD~ΔSBR and ΔRMSSD~ΔET models measure overall reactivity magnitude, not valence. Yet valence is exactly what the Discussion and Conclusion interpret.

2. The HRV result contradicts the Discussion.
RMSSD rose under the negative treatment (47.3 → 57.4 ms). Fig 2C even shows p<0.001 for control vs negative, which the text never reports. The Discussion nonetheless states that HRV fell under the negative treatment, “consistent with horses.” This is the opposite of their own data.

3. The p-values are implausible given the descriptives.
For positive-treatment SBR, the change is 19.0 ± 6.6 in n=34. The paired SE is about 1.1, so t is about 17, yet they report p=0.002. RMSSD (37.7 ± 16) gives t ≈ 14, yet they report p=0.005. Either the model isn’t what’s described, or the reporting is wrong. The degrees of freedom, the full model output and the code are needed.

4. The positive stimulus is confounded with eating.
Lucerne from an 8-L bucket means head lowering, chewing, jaw and facial muscle activity, and dust. Each of these affects blinking mechanically, can raise periocular temperature, and changes cardiac and respiratory patterns. It’s also unclear how blinks were filmed with the head in a bucket. Without heart rate, respiration or a non-food positive stimulus, “positive valence” can’t be separated from “feeding.”

5. Arousal and valence aren’t disentangled, and there’s no manipulation check.
No behavioral indices (ears, posture, approach/avoidance) confirm that the stimuli induced the intended states. The claim that “absolute ET reflects arousal, ΔET reflects valence” is incoherent, since ΔET is a linear function of absolute ET.
Design and statistics

    Crossover design. All three conditions ran in one session with a 1-h washout and 3-min windows. Order is a fixed effect, but carryover, especially after the aversive clipper, isn’t modeled. Order is also partially confounded with time of day across 10:00–14:00.
    Environmental covariates. Ambient temperature (SD 4.5 °C), humidity and wind were measured but not adjusted for in the ET models.
    Count outcome. SBR is a count and would be better modeled with a Poisson or negative-binomial GLMM. Shapiro–Wilk on raw data is the wrong gatekeeper; residuals matter.
    Parallel-slopes assumption. The Δ models force parallel slopes. Treatment × Δ interactions should be tested.
    Shared baseline. All Δs share the same control measurement, so baseline variability and regression to the mean can induce correlation between ΔRMSSD and ΔSBR or ΔET.
    Power analysis. It uses ρ=0.5, a correlation test, which doesn’t match the primary within-subject contrasts. The authors also say horse data were “not used” to derive the effect size, then justify ρ by comparability to horses.
    HRV reporting. They don’t report artefact-correction percentages, heart rate, or respiration. Ultra-short 3-min RMSSD during eating is especially vulnerable to these.
    Habituation criterion. SBR, the outcome itself, was used as the habituation criterion, which is somewhat circular.
    Blinding. Blinding of coders and of the ET extraction isn’t reported, and probably wasn’t feasible since the bucket is visible.

Interpretation and overreach

    “Donkeys are not less sensitive than other animals” can’t be tested without a comparison species under the same protocol.
    The dopamine explanation for SBR is acknowledged as speculative, which is fine. But SBR is also framed as a “simple field indicator” without any reliability or validity data beyond inter-coder agreement.

Minor

    “Control group” should be “control condition,” since this is within-subject.
    “Band-Altman” is a typo.
    The Table 1 title mentions BCS, which is absent from the table.
    Several sentences are duplicated: the HRV paragraph, the max-temperature medial canthus sentence, and the “future research” passage.
    An age of 6.05 ± 0.31 y is suspiciously homogeneous for working donkeys.
    Ref. 19 has a mismatched DOI.
    Data are available only “on request.”

What would rescue it

    Signed deltas.
    Reconciled p-values, with the code shared.
    HR, respiration and ambient-temperature adjustment.
    Behavioral validation of the induced states.
    Ideally, a non-food positive stimulus.

The raw condition means (Table 2, Fig 2) are probably the most trustworthy part of the paper. On those alone, the honest summary is that SBR is bidirectional, while ET and RMSSD rise in both conditions, more under the positive one for RMSSD.

Has the article passed the peer review?
Checking the publication timeline and manuscript status.
Checking the publication timeline and manuscript status.

Yes. It was received on 16 December 2025, accepted on 14 July 2026, and published online on 22 July 2026. What you have is the unedited accepted manuscript (“Article in Press”), released before copy-editing and typesetting, but it has already passed peer review.

The front page notes that if the paper is under Scientific Reports’ Transparent Peer Review model, the reviewer reports will be published with the final version. That would show whether reviewers raised the modelling and Δ-sign issues.

Since it’s past acceptance, the routes for your concerns are post-publication. You could submit a Matters Arising to Scientific Reports, write to the editor about the internal inconsistencies, or post on PubPeer. The contradictions within the paper’s own numbers would make a strong case: the absolute-value Δs, RMSSD rising under the negative condition while the Discussion says it fell, and the implausible p-values. None of these depend on access to the raw data.

Is there any subject that methodically review quality of published research and articles?
Surveying research-integrity watchdogs and detection tools.
Surveying research-integrity watchdogs and detection tools.

Yes. It’s a field called metascience (or meta-research), plus a looser network of research-integrity groups and individual “data sleuths.” The main players fall into a few groups.

Systematic appraisal of evidence

    Cochrane grades bias in trials through systematic reviews (RoB 2, GRADE).
    CAMARADES and SYRCLE do the same for animal studies. SYRCLE’s risk-of-bias tool is the animal-research counterpart of Cochrane’s, and directly relevant to the donkey paper.
    The EQUATOR Network maintains reporting guidelines such as CONSORT, STROBE and ARRIVE. That paper claims ARRIVE compliance, which you could check item by item.

Metascience research centres

    METRICS at Stanford (Ioannidis)
    QUEST at the Berlin Institute of Health
    Center for Open Science, which runs replication projects and the OSF
    Institute for Replication
    The ERROR project (Bern, Malte Elson), which pays reviewers to hunt for errors in published papers

Post-publication scrutiny

    PubPeer, where anonymous comments on specific papers often lead to corrections or retractions
    Retraction Watch and its retraction database, now run by Crossref
    Individual sleuths such as Elisabeth Bik (image manipulation), Nick Brown and James Heathers, and the Data Colada authors

Automated checks

    statcheck recomputes p-values from reported test statistics.
    GRIM, GRIMMER and SPRITE test whether reported means and SDs are arithmetically possible given n.
    The Problematic Paper Screener flags paper-mill output.

Ethics and editorial bodies

    COPE (Committee on Publication Ethics) sets the procedures journals are expected to follow when concerns are raised.

Your check on the donkey paper, recomputing t from the mean change, SD and n and finding the reported p impossible, is exactly the kind of reasoning statcheck and GRIM formalise. With your profile, metascience is a field you could contribute to directly.

Does it make sense to publish a blog about methological review about scientific article about psychiatry and ethology?
Weighing how distinctive the research niche really is.
Weighing how distinctive the research niche really is.

Yes, and your niche is unusually well placed. Few people combine psychiatry, biostatistics and a serious interest in ethology. Psychiatry and animal-behaviour research share the same weak spots: small samples, latent constructs measured through proxies, mis-specified models, and over-interpretation. That gives a blog a coherent identity rather than a random collection of critiques.

There’s precedent for this format working. Andrew Gelman’s Statistical Modeling blog, Data Colada, Neuroskeptic and The Mental Elf (critical appraisal of mental-health research) all have real influence, and some of their posts have led to corrections and retractions. In Italian, methodological critique aimed at clinicians is nearly absent, which is an opportunity.

What makes it work

    A fixed review template: design, measurement validity, model adequacy, internal consistency checks (statcheck, GRIM-style recomputation), reporting-guideline compliance, and whether the conclusions follow. Consistency builds credibility.
    Reproducible R code for every check, so readers can verify the critique itself. This is your strongest differentiator.
    Positive examples too, not only takedowns. Showing what a well-analysed study looks like is more educational and less adversarial.
    Posting substantive findings on PubPeer as well, where authors and editors actually see them.

Risks to manage

    Legal. Defamation (diffamazione) is a criminal offence in Italy. Criticise methods and numbers, never intent or integrity, unless the evidence is overwhelming. Phrase errors as “inconsistent with the reported data” rather than “falsified.”
    Right of reply. Contacting authors before publishing, and updating posts when they respond, protects you and is fair.
    Your own errors. Public critique invites scrutiny, so a careless post costs more credibility than ten good ones earn. Peer-check posts with a colleague when stakes are high.
    Professional relationships. Critiquing work by people you may later collaborate with, examine under, or apply to needs some thought.
    Time. A careful review like the donkey one takes hours. One solid post a month beats frequent shallow ones.

Your quick read of that paper already produced a publishable critique, so the raw material is there. If you decide to start, I can help you build the review template and a reusable R toolkit for the consistency checks.

