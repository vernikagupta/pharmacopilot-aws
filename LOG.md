# Session log

Five lines per session: built, broke, cost, learned, one interview question.

## 27–29 Oct 2026 · Day 1 recon + Day 2 data landing

- **Built:** sandbox recon (notes in `docs/day01-recon.md`); S3 bucket with `raw/`, `corpus/`, `artifacts/`; `scripts/download_data.sh`, which streams the figshare dataset into S3, size-checks every file, unzips 25 time-series CSVs and writes a manifest.
- **Broke:** CloudShell denied on the limited role (implicit deny); fixed by using the admin sandbox role. figshare API returned 400 to a HEAD request; a normal GET worked.
- **Cost:** ~$0. Only S3 storage (~370 MB). Nothing left running.
- **Learned:** federation and roles; implicit vs explicit deny; the account is a shared, governed Organization member; time-series CSVs are semicolon-separated (matters for Athena); 28 MB zip → ~330 MB CSV.
- **Interview question:** Why stream a download into S3 instead of saving it first, and how do you know the file arrived complete?

## Next

Glue table over the semicolon CSVs → Athena queries → convert to Parquet with `CREATE TABLE AS SELECT`. Then the GMP corpus and `PROBLEM.md` (Gate 0).
