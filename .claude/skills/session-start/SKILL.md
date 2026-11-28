---
name: session-start
description: Open a conversation on this repository the methodical way (CONVERSATIONS.md) - read the article STATUS and plan, check the environment and the deadlines, restate the deliverable in five lines. Use at the first message of every conversation, whatever its subject, and whenever Alberto types /session-start.
---

# session-start — the first five minutes of a conversation

The opening line names the unit of work (`P00x stage N: ...`, `P00x correspondence: ...`,
`repo: ...`; see `CONVERSATIONS.md` §1). If it does not, infer the unit from the message and say
which one you took it to be.

## 1. Read, in this order

- Root `CLAUDE.md` (already loaded) and `CONVERSATIONS.md` §2.
- For a paper: `<article>/CLAUDE.md`, the newest STATUS entry in full, its "Next step" and the
  opening line it names; `registry/papers.csv` row; the plan sections the step needs
  (`notes/04_analysis_plan.md` §8 for stages 3–4); for a correspondence unit, `correspondence/contacts.md`
  Log and the last filed message; for stage 5, `protocol/checklist.md` H and I.
- For a repository unit: `protocol/checklist.md` Changes, `protocol/proposals.md`, and the
  `_template/` files the change touches.
- The skills the unit will use: `dagify` (model graphs), `render-check` (after any render),
  `new-review` (stage 1 scaffolding), `session-end` (closing).

## 2. Check the environment (read-only)

- Shell: `which Rscript quarto` must resolve into the nix store; if not, prefix commands with
  `nix-shell --run '...'` from the repo root and say so.
- Stage 4 or any run: `ls "$FITS_DIR"` (archive disk mounted).
- `git status --short`: a dirty tree at the start means the previous conversation did not close
  cleanly; list what is there and ask whether it belongs to this unit before touching it.
- Deadlines: from `registry/papers.csv`, `authors_contacted` plus 21 days and any publication
  date named in a STATUS; print the ones within the next two weeks, with today's date.

## 3. Restate, then work

In five lines or fewer: the deliverable of this conversation; the files it will create or change;
what Alberto will run or send; the check that defines done; the next opening line if this unit
is one step of a sequence. Then start the first step. Do not ask questions the STATUS already
answers; flag an inconsistency between the STATUS and the files immediately.

## 4. During the conversation

One step per round: Claude prepares and explains, Alberto reviews and runs, Claude checks the
outputs. Claude's own runs: parse checks, `stanc`, pandoc previews into the scratchpad, scratch
copies whose outputs go to the scratchpad only, reading tables, draws and logs; each reported as
what it is. Any need that belongs to another unit (another paper, the protocol, a template) goes
into `protocol/proposals.md` or the STATUS "Open questions", not into this conversation.
