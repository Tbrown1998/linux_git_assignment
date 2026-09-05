#!/bin/bash

# ETL script for CoreDataEngineers
# Extracts a CSV from Stats NZ, transforms it, and loads it into Gold.

# Stop the script if any command fails
set -e
# Resolve the folder this script lives in, then work from there.
# Cron does not run from the project folder, so relative paths would break.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# URL stored in an environment variable, as required
export CSV_URL="https://www.stats.govt.nz/assets/Uploads/Annual-enterprise-survey/Annual-enterprise-survey-2023-financial-year-provisional/Download-data/annual-enterprise-survey-2023-financial-year-provisional.csv"

# Where the downloaded file will be saved
RAW_FILE="raw/annual_enterprise_survey_2023.csv"

# ---------- EXTRACT ----------

echo "Starting extract step..."

# -p means no error if the folder already exists
mkdir -p raw

# -f fails on HTTP errors instead of saving an error page
# -L follows redirects, this URL redirects
# -o writes the download to the path we chose
curl -f -L -o "$RAW_FILE" "$CSV_URL"

# Confirm the file arrived and is not empty
# -s is true only if the file exists AND has content
if [ -s "$RAW_FILE" ]; then
    echo "Extract complete: file saved to $RAW_FILE"
else
    echo "Extract failed: file not found in raw folder"
    exit 1
fi
# ---------- TRANSFORM ----------

echo "Starting transform step..."

mkdir -p Transformed

TRANSFORMED_FILE="Transformed/2023_year_finance.csv"

# Rename headers on line 1 only:
#   Variable_code -> variable_code (required by the assignment)
#   Year -> year (assignment asks for lowercase 'year')
# 1s means substitute on line 1 only, so data rows are untouched
sed '1s/Variable_code/variable_code/; 1s/Year/year/' "$RAW_FILE" > /tmp/renamed.csv

# Select the four required columns.
# FPAT treats a quoted field as one unit, so commas inside
# industry names are not mistaken for column separators.
# The header is read first to find each column's position by name,
# so this still works if the source ever reorders its columns.
awk -v FPAT='[^,]*|"[^"]*"' '
NR==1 {
    for (i=1; i<=NF; i++) {
        if ($i=="year") c1=i
        if ($i=="Value") c2=i
        if ($i=="Units") c3=i
        if ($i=="variable_code") c4=i
    }
}
{ print $c1","$c2","$c3","$c4 }
' /tmp/renamed.csv > "$TRANSFORMED_FILE"

# Confirm the file was created and is not empty
if [ -s "$TRANSFORMED_FILE" ]; then
    echo "Transform complete: file saved to $TRANSFORMED_FILE"
else
    echo "Transform failed: file not found in Transformed folder"
    exit 1
fi
# ---------- LOAD ----------

echo "Starting load step..."

mkdir -p Gold

GOLD_FILE="Gold/2023_year_finance.csv"

# Copy rather than move, so the file stays in Transformed as well
cp "$TRANSFORMED_FILE" "$GOLD_FILE"

# Confirm the file was loaded and is not empty
if [ -s "$GOLD_FILE" ]; then
    echo "Load complete: file saved to $GOLD_FILE"
else
    echo "Load failed: file not found in Gold folder"
    exit 1
fi

echo "ETL process finished successfully."
