# Linux and Git Project

Data infrastructure and version control tasks completed for CoreDataEngineers. The project contains two Bash scripts, a scheduled cron job, and the supporting sample data, all versioned with Git.

## Repository structure

```
linux_git_assignment/
├── etl.sh                  # Task 1: extract, transform, load
├── move_files.sh           # Task 3: move CSV and JSON files
├── raw/                    # Downloaded source file (gitignored)
├── Transformed/            # Selected columns
├── Gold/                   # Final loaded output
├── source_files/           # Sample input for move_files.sh
├── json_and_CSV/           # Destination for moved files
├── .gitignore
└── README.md
```

## Requirements

- Bash
- `curl`
- `gawk` (GNU Awk). The transform step uses `FPAT`, which mawk does not support. Confirm with `awk --version`.
- `cron` for scheduled runs

Tested on Ubuntu under WSL2.

## Task 1: ETL script

`etl.sh` runs a three-stage pipeline against the Stats NZ Annual Enterprise Survey 2023 dataset. Each stage prints its progress and confirms its output before the next stage begins.

Run it with:

```bash
chmod +x etl.sh
./etl.sh
```

The script creates its own directories, so it runs correctly from a fresh clone with no manual setup.

### Extract

The source URL is stored in an environment variable, `CSV_URL`, and referenced throughout the script rather than hardcoded at the point of use.

The file is downloaded with `curl -f -L`. The `-f` flag causes curl to fail on an HTTP error rather than writing an error page to disk, and `-L` follows the redirect that the source host issues. The download is written directly into `raw/`.

Confirmation uses `[ -s "$RAW_FILE" ]`, which tests that the file exists *and* is non-empty. Testing existence alone would report success on a zero-byte file.

### Transform

Two header renames are applied to line 1 only, using `sed '1s/.../.../'`. Anchoring to line 1 prevents matching values in the body of the file.

| Source header | Output header | Reason |
|---|---|---|
| `Variable_code` | `variable_code` | Required by the assignment |
| `Year` | `year` | See "Design decisions" below |

Column selection is done by name rather than by fixed position. The header row is read first and each target column's index is resolved from it, so the transform continues to work if the source ever reorders its columns.

`FPAT='[^,]*|"[^"]*"'` is used in place of a plain comma delimiter. This is necessary because the source data is not safely comma-delimited. Field counts across the raw file range from 10 to 22, against a 10-column header, because quoted fields contain embedded commas. Splitting on every comma shifts values into the wrong columns on those rows without producing any error.

The four selected columns are written to `Transformed/2023_year_finance.csv` in the order specified by the assignment: `year, Value, Units, variable_code`.

`cut` was not viable here. It returns fields in ascending position order regardless of the order given to `-f`, and the required output order is not ascending in the source.

### Load

The transformed file is copied to `Gold/` with `cp` rather than `mv`, so it remains present in `Transformed/` as the assignment requires confirmation in both locations.

### Verification

Correctness of the transform was confirmed by:

```bash
# Line counts match, no rows dropped
wc -l raw/annual_enterprise_survey_2023.csv Transformed/2023_year_finance.csv

# Every output row has exactly 4 fields (quote-aware, returns nothing)
awk -v FPAT='[^,]*|"[^"]*"' 'NF != 4' Transformed/2023_year_finance.csv
```

Both files contain 50,986 lines. A naive `awk -F,` check reports false failures on rows where `Value` is quoted, for example `2019,"728,225",Dollars (millions),H01`, which is a correctly formed row.

The pipeline was also tested from a clean state by removing `raw/`, `Transformed/`, and `Gold/` and re-running the script.

## Task 2: Scheduled execution

The script is scheduled to run daily at 12:00 AM via cron:

```
0 0 * * * /home/tosin/win/Desktop/cde/Assignments/linux_git_assignment/etl.sh >> /home/tosin/win/Desktop/cde/Assignments/linux_git_assignment/cron_log.txt 2>&1
```

The five fields are minute, hour, day of month, month, and day of week. `0 0` sets midnight, and the three wildcards apply it to every day.

Absolute paths are required throughout. Cron does not execute from the project directory, so the script resolves its own location at runtime and changes into it:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
```

Without this, the relative paths in the script would write output into the home directory instead of the project folder.

Output is appended to `cron_log.txt`, with `2>&1` redirecting errors to the same file. The log is gitignored as it regenerates on every run.

The schedule was verified by temporarily setting the expression to `* * * * *`, confirming successive complete runs in the log, then restoring `0 0 * * *`.

Under WSL, cron only runs while the WSL instance is active. Scheduled runs will not fire while the host machine is powered off.

## Task 3: File mover

`move_files.sh` moves all CSV and JSON files from `source_files/` into `json_and_CSV/`, handling one or many files of either type.

```bash
chmod +x move_files.sh
./move_files.sh
```

`source_files/` contains sample CSV and JSON files along with `notes.txt`. The text file is included deliberately: it stays in place after the script runs, demonstrating that files are filtered by extension rather than moved indiscriminately.

`shopt -s nullglob` is set before the loop. Without it, an unmatched pattern such as `*.json` is passed through as a literal string, and `mv` fails on a filename that does not exist. With it, the script reports that no matching files were found and exits cleanly. All variable expansions are quoted so filenames containing spaces are handled correctly.

A running count is printed on completion.

## Task 4: Version control

All work is tracked with Git and committed incrementally as each stage was completed, rather than as a single commit at the end. The history reflects the order the project was built in.

`.gitignore` excludes:

- `raw/` — the downloaded source file, 7.7 MB, regenerated on every run
- `cron_log.txt` — regenerated output, not source

## Design decisions

**Lowercasing `Year`.** The assignment specifies selecting a column named `year`, but the source header is `Year`. Rather than assume, the actual header was inspected with `head -1` before writing the transform. The column is renamed to lowercase in the same `sed` operation as the required `Variable_code` rename, so the output matches the assignment specification exactly.

**Selection by name over position.** Hardcoding field numbers would be shorter, but the script runs unattended on a daily schedule against a freshly downloaded file. Resolving indices from the header at runtime means a change in source column order does not silently corrupt the output.

**`set -e`.** Both scripts exit on the first failed command. Without it, a failed download would be followed by a transform against a missing file and a "load complete" message on an empty result.

## Usage

```bash
git clone https://github.com/Tbrown1998/linux_git_assignment.git
cd linux_git_assignment

chmod +x etl.sh move_files.sh

./etl.sh
./move_files.sh
```
