# articles_reviews

Methodological reviews of published research in psychiatry and ethology, with reproducible
checks and Bayesian re-analyses. Published at https://reviews.telepsichiatria.org.

See `CLAUDE.md` for conventions, `protocol/` for the appraisal checklist, `registry/` for the
list of papers and flagged issues.

## Reviews

| id | paper | track | status |
|----|-------|-------|--------|
| P001 | Bukhari et al. 2026, Sci Rep — HRV, eye temperature and blink rate in working donkeys | selected | reading |

## One-time setup (Alberto)

Steps only you can do, in order. Everything else is in the repo.

1. **Create the GitHub repository** `albertoalamia/articles_reviews`, public, empty (no README).
   Then from this folder:
   ```bash
   git remote add origin git@github.com:albertoalamia/articles_reviews.git
   git push -u origin main
   ```
2. **Enable GitHub Pages**: repository → Settings → Pages → Source: *GitHub Actions*.
   The first push to `main` triggers `.github/workflows/publish.yml`. The site appears at
   `https://albertoalamia.github.io/articles_reviews/` until DNS is set.
3. **Custom domain**: Settings → Pages → Custom domain: `reviews.telepsichiatria.org`, tick
   *Enforce HTTPS* once the certificate is issued (can take up to an hour after DNS resolves).
4. **DNS (dnsitalia / your provider)**: add a CNAME record
   `reviews  CNAME  albertoalamia.github.io.`  (TTL default).
5. **Comments**: Settings → General → Features → tick *Discussions*. Create a Discussions category
   named `Reviews` (type: Announcements, so only you and giscus can open threads). Install the
   giscus app on the repository at https://github.com/apps/giscus. Then visit https://giscus.app,
   enter the repo, and compare the generated `repo-id` / `category-id`; if Quarto fails to load
   comments, add those two values under `comments.giscus` in `_quarto.yml`.
6. **WordPress**: add a menu item on telepsichiatria.org linking to
   https://reviews.telepsichiatria.org.
7. **Archive disk**: `/media/alberto/Archive/bayesian/articles_reviews/` already created; keep the disk mounted when sampling.

## Local work

```bash
nix-shell            # or: direnv allow
quarto preview
```
