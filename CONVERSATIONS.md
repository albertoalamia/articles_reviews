# Conversations — how work on this repository is cut into sessions

One conversation is one unit of work on one subject, and it ends in one commit. Everything a
later conversation needs is written into the repository before the commit; nothing lives only in
the chat. These rules exist because three papers run in parallel, each with its own clock, and
because a conversation that mixes subjects leaves each of them half-recorded.

## 1. Units of work

Each line below is one conversation. Open it from the repository root, inside the nix shell.

| unit | opening line (first message) | ends when |
|---|---|---|
| paper, stage 1 | `P00x stage 1: batch B0x draw and scaffold` then `P00x stage 1: reading, checks, concerns, letter` | the letter is sent and logged; registry `inventory` → `authors-contacted` |
| paper, stage 2 | `P00x stage 2: reproduce the authors' analysis` | reproduction log and tables committed |
| paper, stage 3 | `P00x stage 3: plan` then `P00x stage 3: fit` | plan v1.0 committed; stage 3 tables and checks committed |
| paper, stage 4 | `P00x stage 4: programs and prior predictive` then `P00x stage 4: runs and post-processing` | programs compile and prior predictive checked; side-by-side table committed |
| paper, stage 5 | `P00x stage 5: write-up` then `P00x stage 5: render and publish` | review and primer drafted; `draft: false` pushed, registry `published` |
| paper, correspondence | `P00x correspondence: <what arrived or is due>` | message filed, log row, decision recorded, reply drafted for Alberto to send |
| repository | `repo: <topic>` (protocol version, selection rule, templates, lib, skills, site) | the change is committed and the protocol Changes section or `protocol/proposals.md` updated |

Split a unit further when a step needs a run by Alberto that takes time to review (as S1–S5 of a
stage 3 plan do): one conversation per step is fine; one conversation for two steps is fine if
the first is committed before the second starts.

## 2. Rules

1. **One subject per conversation.** Never two papers; never a paper stage and a repository change.
   When a repository need appears mid-stage (a protocol gap, a template fix, a new helper), write
   it in `protocol/proposals.md` with the paper it came from, finish the stage under the protocol
   version in force, and open a `repo:` conversation afterwards.
2. **Open a new conversation when** the unit's commit is pushed; when the subject changes; when a
   reply from the authors arrives (a correspondence conversation, then back to the stage in a new
   one); when the context has been summarised once and the current step is done. Stay in the
   conversation to fix and re-run the step in hand, or to re-render the same deliverable.
3. **The opening line names the unit** in the form above. Claude's first act is to read the article
   `CLAUDE.md` STATUS, the plan sections the step needs and the registry row, check the environment,
   and restate the deliverable, the files it will touch and what Alberto will run, in five lines or
   fewer (skill `session-start`). Then it works.
4. **Every conversation ends with the closing checklist** (skill `session-end`): STATUS entry with
   the next opening line, registry, plan deviations, render check if anything was rendered, a clean
   `git status`, the commit command. A conversation that stops mid-step still ends this way, with
   the STATUS saying exactly where it stopped.
5. **The STATUS "Next step" is the handover contract.** It names the files, the command Alberto
   runs, the check that defines done, and the opening line of the next conversation. A fresh
   conversation that cannot start from it means the previous one ended badly; fix the STATUS first.
6. **Numbers come from files, never from the chat.** After a context summary, Claude re-reads the
   STATUS and the files it edits; a number quoted in a summary is not a source.
7. **Dates are absolute.** Reply windows, publication dates and deadlines are written as dates,
   and `session-start` lists the ones that fall within the next two weeks.
8. **Division of labour is unchanged by any of this.** Claude prepares and checks; Alberto reads,
   runs, renders, sends and commits. Claude's own runs are limited to read-only checks and scratch
   copies whose outputs stay in the scratchpad, and are reported as such.

## 3. Where things live

| what | where | committed |
|---|---|---|
| everything about a paper: notes, numbers, code, plans, logs, correspondence text, STATUS | the article folder | yes |
| protocol, templates, shared code, skills, selection rule, these rules | `protocol/`, `_template/`, `lib/`, `.claude/skills/`, root | yes |
| parked proposals for the protocol or the templates | `protocol/proposals.md` | yes |
| authors' addresses | `<article>/correspondence/addresses.local` | no (gitignored) |
| closed-access PDFs and full texts | `<article>/paper/` with `paper/README.md` naming them | no (per paper; CC-licensed papers may be committed) |
| draws | `$FITS_DIR/<article>/` on the archive disk | no |
| rendered site | `_site/` | no; `_freeze/` yes |
| readable renders of notes, scratch runs, layout trials | the session scratchpad | no; cleared without notice |
| Alberto's preferences, local paths, tool pitfalls | Claude's memory, outside the repository | no |

## 4. Three papers at once

Each paper has its own clock: the three-week window after the letter, the publication date given
to the authors, the batch date for the next systematic draw. Work on one paper per conversation;
let `session-start` print the deadlines so that a window closing during a stage of another paper
is not missed. A correspondence event always takes precedence over the stage in progress: file
it, decide, record, then resume.
