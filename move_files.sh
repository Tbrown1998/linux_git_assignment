#!/bin/bash

# Moves all CSV and JSON files from a source folder
# into a folder named json_and_CSV.

set -e

# Work from the folder this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SOURCE_DIR="source_files"
DEST_DIR="json_and_CSV"

# Stop early if the source folder is missing
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: source folder '$SOURCE_DIR' not found."
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "Moving CSV and JSON files from $SOURCE_DIR to $DEST_DIR..."

# Without nullglob, an unmatched pattern like *.json is passed
# along as literal text and mv fails on a file that doesn't exist
shopt -s nullglob

count=0

# Loop over both file types
for file in "$SOURCE_DIR"/*.csv "$SOURCE_DIR"/*.json; do
    mv "$file" "$DEST_DIR"/
    echo "Moved: $(basename "$file")"
    count=$((count + 1))
done

if [ "$count" -eq 0 ]; then
    echo "No CSV or JSON files found in $SOURCE_DIR."
else
    echo "Done. $count file(s) moved to $DEST_DIR."
fi
