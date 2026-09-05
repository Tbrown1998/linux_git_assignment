#!/bin/bash

# ETL script for CoreDataEngineers
# Extracts a CSV from Stats NZ, transforms it, and loads it into Gold.

# Stop the script if any command fails
set -e

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
