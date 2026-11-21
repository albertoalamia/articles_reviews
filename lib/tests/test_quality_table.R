library(testthat)

tax <- data.frame(code = c("DES-UNIT", "MEA-SCALE", "CON-STAT", "INF-FOLLOW", "REP-CODE"),
                  domain = c("design", "measurement", "consistency", "inference", "reporting"),
                  label = c("Unit", "Scale", "Stat", "Follow", "Code"), description = "", stringsAsFactors = FALSE)
iss <- data.frame(paper_id = c("P9", "P9", "P9", "P9", "P8"),
                  issue_code = c("DES-UNIT", "CON-STAT", "CON-STAT", "REP-CODE", "INF-FOLLOW"),
                  severity = c("major", "critical", "minor", "minor", "critical"),
                  evidence = c("inferred", "confirmed", "confirmed", "needs-data", "confirmed"),
                  location = c("Methods", "Table 2", "Table 1", "Declarations", "Discussion"),
                  note = "", stringsAsFactors = FALSE)

test_that("rating rule follows the protocol", {
  expect_equal(rate_domain(character(0)), "no concern found")
  expect_equal(rate_domain(c("minor", "minor")), "minor concerns")
  expect_equal(rate_domain(c("minor", "major")), "major concerns")
  expect_equal(rate_domain(c("major", "critical")), "conclusions at risk")
})

test_that("quality_table has one row per domain with the right counts and main point", {
  q <- quality_table("P9", iss, tax)
  expect_equal(nrow(q), 6)
  expect_equal(q$Domain, unname(domain_order))
  cons <- q[q$Domain == "Internal consistency", ]
  expect_equal(c(cons$Critical, cons$Major, cons$Minor), c(1, 0, 1))
  expect_equal(cons$Rating, "conclusions at risk")
  expect_equal(cons$`Main point`, "Stat (Table 2)")
  expect_equal(q$Rating[q$Domain == "Model adequacy"], "no concern found")
  expect_equal(q$`Needs data`[q$Domain == "Reporting"], 1)
})

test_that("main points can be overridden per domain", {
  q <- quality_table("P9", iss, tax, main_points = c(design = "pseudoreplication"))
  expect_equal(q$`Main point`[q$Domain == "Design"], "pseudoreplication")
})

test_that("unknown codes and tags are errors, not silent zeros", {
  bad <- iss; bad$issue_code[1] <- "XXX-NOPE"
  expect_error(quality_table("P9", bad, tax), "unknown issue code")
  bad2 <- iss; bad2$severity[1] <- "huge"
  expect_error(quality_table("P9", bad2, tax), "severity")
})

test_that("programme_table lists only the requested statuses", {
  papers <- data.frame(id = c("P9", "P8"), first_author = c("A", "B"), year = c(2026, 2025),
                       journal = "J", field = "f", track = c("selected", "systematic"),
                       verdict = c("major concerns", ""), status = c("published", "draft"),
                       date_review_published = c("2026-01-01", ""), stringsAsFactors = FALSE)
  pt <- programme_table(papers, iss, tax)
  expect_equal(nrow(pt), 1)
  expect_equal(pt$Paper, "A 2026")
  expect_equal(pt$`Worst domain`, "Internal consistency")
  expect_equal(nrow(programme_table(papers, iss, tax, status = "none")), 0)
})
