# coppock_green_2015/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original_extracted/ (run download_original.R first)
# Description: Runs every deposited script, twice, and records how each run ended
#   and what it did to the files the deposit ships.
#
#   The deposit is flat and every script reads and writes in its working directory,
#   so each pass runs in its own scratch copy: running the deposit in place would
#   write over five of its own files. The stripped pass withholds the five files the
#   deposited code itself writes (meanstable.csv, setoftwelve.rdata and the three
#   figure PDFs), which is the only way to see whether a script passes on its own work
#   or on an output the deposit ships. The as-shipped pass restores them. Scripts run
#   in the order the deposit's readme lists them, which is also the order the stripped
#   pass needs: Figure 2 writes setoftwelve.rdata before Figure 3 and the
#   disattenuation script read it.
#
#   This script is not part of run_all.R. It needs gplots and calibrate, which the
#   deposit loads and the maintained rewrite does not, and its two tables are
#   committed so that nothing downstream needs them.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposit <- here::here("original_extracted", "Coppock Green Lab Field Replication Archive")
stopifnot(dir.exists(deposit))

# Scripts, in the readme's order ----
# tables1and2.r is an undocumented copy of the Tables 1 and 2 script without its header.
# It is run, but the readme does not list it, so it is recorded as other.
scripts <- tribble(
  ~script, ~role,
  "Coppock Green Lab Field Tables 1 and 2 Code.R", "analysis",
  "Coppock Green Lab Field Figure 1 Code.R", "analysis",
  "Coppock Green Lab Field Figure 2 Code.R", "analysis",
  "Coppock Green Lab Field Figure 3 Code.R", "analysis",
  "Coppock Green Lab Field Appendix Table Code.R", "analysis",
  "Coppock Green Lab Field Disattenuation Code.R", "analysis",
  "tables1and2.r", "other"
)

# The deposited files that deposited code also writes.
shipped_outputs <- c("meanstable.csv", "setoftwelve.rdata", "tiles_landscape.pdf",
                     "standardized.pdf", "rankorderrobustness.pdf")

stopifnot(all(file.exists(file.path(deposit, c(scripts$script, shipped_outputs)))))

# Stage a scratch copy of the deposit ----
stage <- function(label, include_outputs) {
  # normalizePath, because tempdir() resolves through /private on macOS, and the
  # scrubbing below has to see the same spelling the error messages carry.
  root <- file.path(normalizePath(tempdir(), winslash = "/", mustWork = FALSE),
                    str_c("coppock_green_2015_", label))
  unlink(root, recursive = TRUE)
  dir.create(root, recursive = TRUE)
  files <- list.files(deposit, all.files = TRUE, no.. = TRUE)
  if (!include_outputs) files <- setdiff(files, shipped_outputs)
  file.copy(file.path(deposit, files), root)
  root
}

# Run each script in its own process ----
# The scripts share names across their workspaces, so sourcing them into this session
# would let one script's leftovers rescue the next.
run_one <- function(root, script) {
  log_file <- file.path(dirname(root), str_c(basename(root), "_", make.names(script), ".log"))
  expr <- str_c("setwd(", deparse(root), "); source(", deparse(script), ", echo = FALSE)")
  status <- system2(file.path(R.home("bin"), "Rscript"), args = c("-e", shQuote(expr)),
                    stdout = log_file, stderr = log_file)
  lines <- read_lines(log_file)
  first <- which(str_starts(lines, "Error"))
  stopped_at <- if (length(first) == 0) {
    NA_character_
  } else {
    lines[first[1]:min(first[1] + 2, length(lines))] |>
      discard(\(x) str_detect(x, "Execution halted")) |>
      str_c(collapse = " ") |>
      str_replace_all(fixed(root), "<deposit>") |>
      str_replace_all(fixed(str_remove(root, "^/private")), "<deposit>") |>
      str_squish() |>
      str_trunc(220)
  }
  tibble(script = script, exit_status = status, stopped_at = stopped_at)
}

run_pass <- function(root) map(scripts$script, \(s) run_one(root, s)) |> list_rbind()

# Whether a rewritten file carries the deposit's contents ----
# A CSV is compared as a table, because the deposit was written with Windows line
# endings. An .rdata file is compared object by object at a tolerance that absorbs the
# last bit of a double. A PDF is compared byte for byte once the device's two
# timestamps are blanked, so FALSE there means the drawing instructions differ, which
# the README shows can happen with every mark in the same place.
blank_timestamps <- function(path) {
  raw_pdf <- readBin(path, "raw", file.size(path))
  hits <- grepRaw("D:[0-9]{14}", raw_pdf, all = TRUE)
  for (h in hits) raw_pdf[h:(h + 15L)] <- charToRaw("D:19700101000000")
  raw_pdf
}

same_contents <- function(file, path) {
  deposited <- file.path(deposit, file)
  if (str_ends(file, "\\.csv")) {
    identical(read_csv(path, col_types = cols(.default = col_character())),
              read_csv(deposited, col_types = cols(.default = col_character())))
  } else if (str_ends(file, "\\.rdata")) {
    fresh <- new.env()
    original <- new.env()
    load(path, envir = fresh)
    load(deposited, envir = original)
    isTRUE(all.equal(mget(sort(ls(fresh)), fresh), mget(sort(ls(original)), original),
                     tolerance = 1e-12))
  } else {
    identical(blank_timestamps(path), blank_timestamps(deposited))
  }
}

checksums <- function(root) {
  files <- list.files(root, all.files = TRUE, no.. = TRUE)
  set_names(unname(tools::md5sum(file.path(root, files))), files)
}

# The stripped pass ----
stripped_root <- stage("stripped", include_outputs = FALSE)
stripped_before <- checksums(stripped_root)
stripped <- run_pass(stripped_root)
stripped_after <- checksums(stripped_root)

# The as-shipped pass ----
shipped_root <- stage("as_shipped", include_outputs = TRUE)
shipped_before <- checksums(shipped_root)
as_shipped <- run_pass(shipped_root)
shipped_after <- checksums(shipped_root)

# Archive run status, one row per script per pass ----
run_status <- bind_rows(as_shipped = as_shipped, stripped = stripped, .id = "pass") |>
  left_join(scripts, by = "script") |>
  transmute(pass, script, role, exit_status,
            outcome = if_else(exit_status == 0, "clean", "error"),
            stopped_at)

stopifnot(nrow(run_status) == 2 * nrow(scripts), !anyNA(run_status$role))

# Archive overwrites ----
# Under the stripped pass every withheld output has a row: rebuilt if the deposit's own
# code wrote it again, withheld if it did not. Under the as-shipped pass a deposited file
# has a row only where the run changed its bytes. Under either pass a file no deposit
# member names is added.
stripped_rows <- tibble(file = shipped_outputs) |>
  mutate(
    rebuilt = file %in% names(stripped_after),
    pass = "stripped",
    effect = if_else(rebuilt, "rebuilt", "withheld"),
    matches_deposit = map2_lgl(file, rebuilt, \(f, r) {
      if (r) same_contents(f, file.path(stripped_root, f)) else NA
    })
  )

shipped_rows <- tibble(file = names(shipped_before)) |>
  filter(shipped_after[file] != shipped_before[file]) |>
  mutate(
    pass = "as_shipped",
    effect = "overwritten",
    matches_deposit = map_lgl(file, \(f) same_contents(f, file.path(shipped_root, f)))
  )

added_rows <- bind_rows(
  tibble(pass = "stripped",
         file = setdiff(names(stripped_after), c(names(stripped_before), shipped_outputs))),
  tibble(pass = "as_shipped", file = setdiff(names(shipped_after), names(shipped_before)))
) |>
  mutate(effect = "added", matches_deposit = NA)

overwrites <- bind_rows(shipped_rows, stripped_rows, added_rows) |>
  select(pass, file, effect, matches_deposit)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status, n = nrow(run_status), width = 200)
print(overwrites, n = nrow(overwrites))
