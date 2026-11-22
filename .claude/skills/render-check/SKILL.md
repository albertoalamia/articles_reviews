---
name: render-check
description: Check a Quarto render of a review or primer (PDF pages, figures, freeze folder, stray files) after Alberto has run quarto render, and hand him the commit command. Use whenever Alberto says "done, check the render" or a render precedes a commit.
---

# render-check — after `quarto render`, before the commit

Division of labour: Alberto runs `quarto render`, the tests and the analysis scripts; Claude
never does. Claude may run read-only checks: `pdfinfo`, `pdftotext`, `pdftoppm` into the
scratchpad, `git status`, `ls`, reading `_freeze/` and `_site/`, `quarto pandoc` previews of
notes. If the session was started outside the nix shell, wrap each command in
`nix-shell --run '...'` from the repo root (first run fetches nixpkgs; later ones are quick).

Outputs live in `_site/<article>/review.pdf` and `review.html` (never in the article folder);
figures in `_freeze/<article>/review/figure-html/` and `figure-pdf/`; executed results in
`_freeze/<article>/review/execute-results/html.json` and `tex.json`.

## Checklist

1. **Did it finish?** `ls -la --time-style=+%H:%M _site/<article>/` — timestamps of `review.pdf`
   and `review.html` must be the render time. A 90-byte `review.html` is a draft page (`draft:
   true` with `draft-mode: gone`): expected until publication; read the HTML with
   `quarto preview <article>/review.qmd -M draft:false` (Alberto) or check the PDF instead.
   Leftover `<name>.tex` / `<name>.log` in an article folder mean an interrupted or failed
   LaTeX run (`grep -n '^!' <name>.log`); they are deleted, never committed.

2. **Figures in the freeze.** List both figure folders. Expected: exactly the files of the
   current chunk labels (`<label>-<n>.png|pdf`). Quarto never deletes files of renamed or
   removed chunks; stale ones must be removed by hand before the commit (`rm` for untracked,
   `git rm` for tracked). Open every new or changed PNG with the Read tool and look at it.

3. **PDF pages.** `pdfinfo` for the page count (compare with the previous render), then
   `pdftotext -layout` to locate section titles and captions:
   `grep -n -E 'Figure [0-9]+:|^ *\([a-d]\) |<section title>'`. Rasterise the pages with
   figures or tables that changed: `pdftoppm -r 60 -f <p> -l <p> -png review.pdf <scratchpad>/x`
   and Read the image. Known failure modes: a multi-panel chunk without a `fig-` label gives
   every panel "(a)" and loses the figure caption; without `fig-subcap` the caption is repeated
   under each panel; a floating figure after a longtable can be pushed to a page of its own;
   wide pipe tables overlap when headers are short; math in captions must be plain words.

4. **Numbers.** Every number in the review comes from code: spot-check that inline values near
   the changed text are `{r}` expressions, not typed digits, and that `html.json` changed if
   any computed value changed.

5. **Stray files.** `git status --short`: nothing under `_site/`, no `*.tex`, `*.log`,
   `*_files/`, no scratch R scripts in the article folder. New files under `lib/`, `tools/`,
   `_freeze/` are expected when they belong to the change.

6. **Report** to Alberto in a few lines: what is right, what is wrong with the page number and
   the cause, what he must delete or re-run. If a fix touches the sources, make it, say which
   stale freeze files it will create, and give the render command again. Only when a render is
   clean give the commit.

## Commit command

From the repo root; explicit paths, `-A` so deletions are picked up; message with a title
line, a blank line, bullets if useful, then the two trailers:

```
git add -A <paths...> _freeze
git commit -m "<Title: what and where>

- <bullet>

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
Claude-Session: <session URL from the system reminder>"
```

Alberto pushes. `_freeze/` is committed, `_site/` is not. After the push the GitHub Action
renders the whole site from the freeze without R, so site-wide settings in `_quarto.yml`
reach every page even if only one was rendered locally.
