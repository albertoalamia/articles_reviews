---
name: session-end
description: Close a conversation on this repository (CONVERSATIONS.md) - STATUS entry with the next opening line, registry, plan deviations, render check, clean git status, commit command. Use when the unit of work is done or when Alberto says "let's stop here", "new conversation" or types /session-end.
---

# session-end — nothing lives only in the chat

Run through every item; say which ones did not apply.

1. **STATUS entry** in `<article>/CLAUDE.md` (newest first), dated, with four fields and a fifth
   line:
   - Done: files created or changed, runs made and by whom, results in one line each with the
     numbers that matter.
   - Decided (and why): every choice a later reader could question, with the reason.
   - Open questions: what is unresolved, including anything parked for another unit.
   - Next step: the files, the command Alberto runs, the check that defines done.
   - Open the next conversation with: `P00x stage N: ...` (the exact line).
   A conversation that stops mid-step says so here, naming the half-done files.
   For a `repo:` unit the entry goes into the root `CLAUDE.md` layout or `protocol/checklist.md`
   Changes, as appropriate, and `protocol/proposals.md` is updated.
2. **Registry.** `registry/papers.csv`: status, protocol_version, authors_contacted,
   reply_received, verdict, date_review_published as they stand now. `registry/issues.csv` agrees
   with `notes/03_concerns.md` (same count, same severities and tags).
3. **Plan and logs.** Any departure from `notes/04_analysis_plan.md` has a row in its §7;
   reconstruction or data changes have a line in the data log; a new concern has its four places
   (concerns file, registry, inventory, review text if written).
4. **Render.** If anything was rendered, the `render-check` skill has been followed: figures
   looked at, stale freeze files removed, PDF pages checked.
5. **Working tree.** `git status --short` reviewed line by line: everything that belongs to the
   unit is listed for the commit; nothing that must stay out is there (addresses, closed-access
   PDFs and full texts, `.tex`/`.log`, `_site/`, scratch scripts). Untracked `_freeze/` files from
   a render are committed with it.
6. **Commit command**, from the repo root, explicit paths, `-A` where deletions occur, title line
   plus bullets if useful, then the trailers:
   ```
   git add -A <paths...>
   git commit -m "<Paper or repo: what and where>

   Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
   Claude-Session: <session URL from the system reminder>"
   ```
   Alberto pushes. Nothing uncommitted is left behind on purpose.
7. **Scratchpad.** Anything there that a later conversation needs (a readable render, a scratch
   result) is either moved into the repository or named in the STATUS as reproducible; the
   scratchpad may be cleared at any time.
8. **Memory.** Save only what is durable and not in the repository: a preference, a tool pitfall,
   a local path. Paper content never goes to memory.
9. **Last line to Alberto:** the opening line of the next conversation and the date of the nearest
   deadline.
