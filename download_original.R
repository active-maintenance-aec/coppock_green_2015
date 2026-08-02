# coppock_green_2015/download_original.R
# Output: original/ (the deposited archive, not redistributed in this repo)
#         original_extracted/ (its 16 members, also not redistributed)
# Depends on: original_manifest.csv, original_members_manifest.csv
# Description: Fetch the deposited archive from Harvard Dataverse, verify it, and
#   unpack it. Run this once before running anything in maintained/. Re-running is
#   free: a file already present with the right checksum is not downloaded again.
#
#   This deposit is a single RAR container rather than a set of individual files,
#   so verification happens twice. original_manifest.csv pins the container, in the
#   format every repository in this program uses; original_members_manifest.csv pins
#   the 16 files inside it, so that a reader can tell an intact unpacking from a
#   partial one without opening the container by hand.
#
#   The container manifest carries two checksums. md5_served is the MD5 of the bytes
#   Dataverse returns for `?format=original`, which is what this code was written
#   against. md5_published is the checksum Dataverse displays. Here the two agree,
#   but they do not always: other deposits in this program carry published checksums
#   that verify neither the original file nor the tabular file derived from it, so
#   verification runs against md5_served and any disagreement is reported.

library(tidyverse)
library(here)
library(archive)

here::i_am("download_original.R")

dataset_doi <- "doi:10.7910/DVN/25543"
base_url <- "https://dataverse.harvard.edu/api/access/datafile"

# Manifest ----
manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

dir.create(here::here("original"), showWarnings = FALSE)

# Download what is missing or wrong ----
# format=original asks for the deposited bytes rather than any representation
# Dataverse derives from them.
planned <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{dataverse_file_id}?format=original"),
    md5_local = unname(tools::md5sum(path)),
    needs_download = is.na(md5_local) | md5_local != md5_served
  )

walk2(
  planned$url[planned$needs_download],
  planned$path[planned$needs_download],
  function(url, path) download.file(url, destfile = path, mode = "wb", quiet = TRUE)
)

print(str_glue("Downloaded {sum(planned$needs_download)} of {nrow(planned)} files; ",
               "{sum(!planned$needs_download)} already present and verified."))

# Verify the container ----
verified <- planned |>
  mutate(
    md5_downloaded = unname(tools::md5sum(path)),
    match = md5_downloaded == md5_served,
    published_agrees = md5_served == md5_published
  ) |>
  select(file, bytes, md5_served, md5_downloaded, match, published_agrees)

print(verified, n = nrow(verified))

if (!all(verified$match)) {
  stop("Checksum mismatch: the downloaded archive does not match what Dataverse served when this code was written.")
}

print(str_glue("All {nrow(verified)} files match. ",
               "{sum(!verified$published_agrees)} carry a published checksum that disagrees."))

# Unpack ----
# The scripts in maintained/ read from original_extracted/, never from original/,
# so that original/ holds the deposit and nothing else. Unpacking into the deposit
# directory is how coppock_2019a lost five deposited files in March 2026: the
# archive's own scripts write their outputs back beside their inputs, and where
# those outputs are themselves deposited files the run silently overwrites part of
# the deposit.
extract_dir <- here::here("original_extracted")
unlink(extract_dir, recursive = TRUE)
dir.create(extract_dir, showWarnings = FALSE)
archive::archive_extract(planned$path[1], dir = extract_dir)

# Verify the members ----
members <- read_csv(here::here("original_members_manifest.csv"), show_col_types = FALSE) |>
  mutate(
    path = file.path(extract_dir, "Coppock Green Lab Field Replication Archive", member),
    md5_extracted = unname(tools::md5sum(path)),
    match = !is.na(md5_extracted) & md5_extracted == md5
  )

print(members |> select(member, bytes, md5, md5_extracted, match), n = nrow(members))

if (!all(members$match)) {
  stop("Checksum mismatch: the unpacked archive does not match the deposited members.")
}

print(str_glue("All {nrow(members)} members unpacked and verified into original_extracted/."))
print(str_glue("Archive: {dataset_doi}"))
