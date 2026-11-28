# Copyright and access — DRAFT of version 1.1 (2026-11-28), not in force

Draft replacement for §2 of `copyright.md` v1.0 ("Reading and analysing a class B paper"), with
the environment that enforces it. Everything else in v1.0 (classes, quotation, the 400-word
ceiling, numbers, figures, data) stands. Written by a reviewer and an AI assistant; not legal
advice. The basis of §2 is Alberto's decision of 2026-11-28, taken on an assumption that is
stated in §2 and has not been verified against the contract.

## 0. Position

A published paper is open to criticism whatever its licence. The law protects that: quotation
for criticism (l. 633/1941 art. 70; Berne art. 10), and facts and ideas are not protected at all.
What a subscription licence restricts is the *copying and processing of the text*, not the
review. The programme therefore reviews class B papers to the same standard as class A, and
changes only where the text is processed and by which tool.

## 1. What was found (read 2026-11-28)

| source | what it says | consequence |
|---|---|---|
| Elsevier website terms, "Using our services" (last revised 12 March 2026) | "You may not use Content from the Services in combination with an artificial intelligence tool", including to "process, analyse, generate output", "except as otherwise expressly permitted under these Terms and Conditions, or any relevant license or subscription agreement" or authorisation. Where an institutional subscription or licence agreement conflicts, "the latter terms shall control". Dutch law. | The default is no AI tool of any kind, local or remote. The institution's agreement decides. |
| Elsevier, product terms for subscribed products, §1.1 (standard terms; no date) | Authorized Users may use the products with an AI tool that "(a) is used in a closed hosted (enterprise-grade) environment solely for the individual use by the Authorized User, (b) does not train the algorithm of an external artificial intelligence tool" and "(c) does not share the Subscribed Product or any part thereof with a third party". | Elsevier's current standard licence allows a closed, individual, non-training tool. Whether the Italian contract carries this clause is not known. |
| Elsevier FAQ on generative AI (updated 16 November 2026; written for corporate customers) | "Elsevier's legal agreements do not permit its content and products to be processed through public AI tools (such as public versions of chat based LLMs)". | A cloud assistant on a personal plan is what Elsevier calls a public tool. |
| Elsevier text-and-data-mining policy | Researchers at subscribing academic institutions may text mine subscribed content "for non-commercial research purposes and in accordance with their institution's agreement". | Again the institution's agreement. v1.0 §2 rested on this and on the copyright-policy sentence alone; that was too little. |
| CRUI-CARE / Elsevier ScienceDirect contract 2023–2027 | Text not public (CRUI publishes the procurement record only; the CARE page has no detail sheet). | Not asked (Alberto, 2026-11-28). §2 rests on an assumption about it. |
| Bicocca library | Remote access for institutional users with a university address; external users on site only, "solo se le licenze d'uso lo consentono". No published rule on AI tools. Use of each resource follows its licence. | Alberto is an authorised user with a university address (stated 2026-11-28). The programme is his own work, outside the university: whether the licence covers personal non-commercial research by an authorised user is assumed (personal scholarly use). |
| l. 633/1941 art. 70-ter (text as updated 9 August 2026) | Research organisations (universities included) may reproduce lawfully accessed works for text and data mining for scientific research; copies kept securely; contract clauses against this are void (c. 9). | A statutory route that a licence cannot remove, but only for work done *by or within* a research organisation, and only if analysing one article counts as mining (the definition speaks of analysing large quantities; not verified on the official text). Not available: the programme is Alberto's own work, not the university's (2026-11-28). |
| art. 70-quater | Mining by anyone, unless the right holder has expressly reserved it. Elsevier has (the line printed on the article). | Not available. |
| art. 70-septies (l. 132/2025) | Mining through AI systems, generative included, is allowed within 70-ter and 70-quater. | Adds nothing beyond those two. |
| Claude Code data handling (code.claude.com, data usage) | Text read by the assistant is sent to the provider; on a consumer plan it is kept 30 days if model training is switched off, 5 years if on; on commercial terms it is not used for training, 30 days. Session transcripts are stored locally in plain text. | Reading a class B text with the cloud assistant is a transmission to a third party, with a training setting to check. |

Not found, and said so: the CRUI contract text; the Directive (EU) 2019/790 recitals on relying
on third parties for mining (EUR-Lex did not load); the official Normattiva text of the articles
(read on a commentary site).

## 2. The rule: hosted assistant, individual use, no training

**Decision (Alberto, 2026-11-28).** Class B papers are read and appraised like class A, with
the assistant, on this basis:

> *Assumption.* The institution's Elsevier agreement allows an authorised user what Elsevier's
> standard terms for subscribed products allow: an AI tool in a closed hosted environment, for
> the individual use of the authorised user, that trains no external model and shares the
> content with no third party. The assistant is used on a consumer plan (Max) with model
> training disabled: one user, content not used for training, 30-day retention, nothing passed
> on. That is taken to meet the substance of the description. Personal, non-commercial
> scholarly work by an authorised user is taken to be within the licence.

What is not verified: that the CRUI contract carries the clause; that Elsevier would accept
this reading (its FAQ says its agreements do not permit "public AI tools", and a consumer plan
is one). Where the reading is weakest: "closed hosted (enterprise-grade)" most plausibly means
a provider bound by contract; on a consumer plan the protection is an account setting. The
argument is substance over form: the interests the clause protects (individual use, no
training, no onward sharing) are all met. An API key under the provider's commercial terms
would add the contractual guarantee; considered and not taken (Alberto, 2026-11-28), and it
remains the first step up if the basis is challenged. The library and the
publisher have not been asked. The risk accepted is contractual (a complaint, loss of access,
a reply that attacks the process), not the lawfulness of what is published.

**Conditions, all required.**

1. **Training off, as a checked fact.** Model training is disabled in the account's privacy
   settings: verified by Alberto on 2026-11-28, and again at the scaffold of every class B
   paper, with the date on the "Access and licence" line. If it is found on, class B work stops
   until it is off and the event is recorded here.
2. **Minimisation.** The text is read for the appraisal of that paper only; never passed to web
   tools, other services or other people; one local copy; no feedback rating (thumbs) in a
   session that has read a class B text, since a rating may submit the conversation outside
   the training setting (a precaution, not verified); local session transcripts kept short
   (`cleanupPeriodDays`).
3. **Output limits unchanged.** Under 400 verbatim words in the committed files
   (`tools/quote_audit.py`), every quotation discussed and attributed, numbers as facts, no
   whole tables, no figures (v1.0 §3). New: `tools/quote_check.py` confirms each quotation is
   verbatim and gives its page.
4. **Stated in the open.** The protocol page of the site says what is done and on what
   assumption, dated.
5. **Tripwire.** If the publisher, the library or a revised text of the terms says otherwise,
   that publisher's papers go to the fallback of §3 from that day, and the change is dated here.
6. **Per publisher.** The assumption is about Elsevier's wording. At the scaffold of the first
   paper of any other publisher, its terms on AI tools are read and a row is added below.

| publisher | terms read | basis for the assistant | since |
|---|---|---|---|
| Elsevier | website terms 12 March 2026; subscribed-product terms §1.1; FAQ 16 November 2026 | assumption above (consumer plan, training off), conditions 1–6 | 2026-11-28 |

## 3. Open zone, and the fallback

**Open zone**: what any session may read and what may be committed.

| item | why it is free |
|---|---|
| bibliographic record, DOI, open metadata | facts, open licences |
| numbers transcribed from text, tables and figures, with page pointers (`data/raw/*.csv`) | facts |
| the design and methods described in the reviewer's own words (`notes/02_methods_inventory.md`) | ideas and facts; the expression is the reviewer's |
| the sentences the review criticises, each with page, total under 400 words | art. 70 |
| the authors' public data and code under an open licence (class C) | its licence |
| an openly licensed preprint or accepted manuscript | class A |
| everything the programme produces | own work |

**Local zone**: the PDF, the extracted full text, the supplement, rasters, whole copied tables,
reading notes with verbatim passages. Read by the assistant under §2; never committed.

**Fallback (documented, not built).** If the tripwire fires, the local zone is read by Alberto
and by offline tools only: a local language model as second reader (extraction of the inventory
with page pointers; answers to the assistant's written questions, targeted facts and never a
running paraphrase; this machine runs a quantised model of about 8–14 billion parameters on its
8 GB GPU, larger ones slowly; the pinned nixpkgs has `llama-cpp` and `ollama`), everything that
crosses to the open zone gated by `quote_audit.py` and Alberto's reading, and the pipeline
calibrated first on P001 and P002 against the assistant's direct reading.

## 4. Guard

Under §2 the assistant may read the local zone, so nothing blocks reading. What is guarded is
what leaves: `.gitignore` keeps the local zone out of the repository; `quote_audit.py` runs
before every commit of a class B folder; `quote_check.py` verifies the quotations.
`protocol/local_zone.txt` lists the local-zone paths of every class B folder, so that the
fallback's hook (`tools/guard_local_zone.py`, refusing every tool call that names one of them)
can be switched on the day the tripwire fires.

## 5. P003 as it stands

- The assistant read the full text and the supplement on 2026-11-25 and 2026-11-27, on the
  same plan and setting as §2 describes; P003 continues under §2. The letter and stages 2–4
  need only the open zone (Zenodo data, CC BY; the inventory; the numbers).
- The uncommitted compliance work (reading notes and whole tables local, audit under 400) is
  still required by condition 3 and is committed as its own unit.
- Transcripts of those two days hold passages of the text, locally: they expire with the
  retention setting, or are deleted (Alberto).
- The pushed history still holds the reading notes (823 verbatim words) and the whole Tables
  S2–S3: `proposals.md` row 3, unchanged.

## 6. If adopted: files to change

`protocol/copyright.md` (v1.1: §2 replaced by §2–4 above, §5 procedure, §6 table, §8 sources,
Changes); `_template/CLAUDE.md` (access line gains "assistant: full text under copyright.md §2
| open zone only"); `_template/paper/README.md`; `.claude/settings.json` (`cleanupPeriodDays`),
`protocol/local_zone.txt`, `tools/quote_check.py` (the hook `tools/guard_local_zone.py` only
with the fallback); skills `new-review` (publisher row, local-zone paths, training setting
re-checked and dated) and `session-start` (reminds of §2 conditions for a class B paper); `protocol.qmd` (condition 4); root `CLAUDE.md` (Rules, Layout);
`protocol/proposals.md` (row 4 closed).

## Sources

- Elsevier website terms and conditions: https://www.elsevier.com/legal/elsevier-website-terms-and-conditions
- Elsevier, terms for subscribed products: https://www.elsevier.com/legal/msa-product-specific-terms-conditions-for-subscribed-products
- Elsevier, text and data mining: https://www.elsevier.com/about/policies-and-standards/text-and-data-mining
- Elsevier, FAQ on generative AI: https://www.elsevier.support/dataasaservice/news/faqs-on-the-commercial-use-of-elsevier-content-with-generative-ai
- CRUI, contract record: https://www.crui.it/bandi-di-gara-e-contratti-pubblici/contratto-science-direct-2023-2027.html ; CARE: https://risorselettroniche.crui.it/care-contratti/
- Bicocca library (not consulted on the AI question), remote access and external users: https://www.biblio.unimib.it/it/risorse/accesso-alle-risorse-remoto ; https://www.biblio.unimib.it/it/servizi/utenti-esterni-e-alumni
- l. 633/1941 art. 70, 70-ter, 70-quater, 70-septies, as on brocardi.it (updated 9 August 2026)
- Claude Code, data usage, permissions, sandboxing, hooks: https://code.claude.com/docs/en/data-usage
