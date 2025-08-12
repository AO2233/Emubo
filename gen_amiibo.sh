#!/bin/bash
# Converts .bin amiibo files to .eml and .key files.
set -euo pipefail

# --- FUNCTIONS ---
# Converts a single .bin file.
# Arg1: Source .bin file path
# Arg2: Destination directory path
process_bin_file() {
    local BIN_FILE=$1
    local OUTPUT_DIR=$2

    if [ ! -f "$BIN_FILE" ]; then
        echo "Error: Input file not found at '$BIN_FILE'" >&2
        return 1
    fi

    echo "Processing '$BIN_FILE'...'"
    local BASENAME
    BASENAME=$(basename "$BIN_FILE" .bin)
    local EML_FILE="$OUTPUT_DIR/$BASENAME.eml"
    local KEY_FILE="$OUTPUT_DIR/$BASENAME.key"
    mkdir -p "$OUTPUT_DIR"

    # Run converter, capturing stderr to extract the UID.
    local TEMP_STDERR
    TEMP_STDERR=$(mktemp)
    if ! pm3_amii_bin2eml.pl "$BIN_FILE" > "$EML_FILE" 2> "$TEMP_STDERR"; then
        echo " -> Error: Converter script failed for '$BIN_FILE'." >&2
        rm "$TEMP_STDERR"
        return 1
    fi

    # Extract UID from the converter's output.
    local UID_LINE
    UID_LINE=$(grep "hf 14a sim -t 7 -u" "$TEMP_STDERR")
    rm "$TEMP_STDERR"

    if [ -n "$UID_LINE" ]; then
        local AMIIBO_UID
        AMIIBO_UID=$(echo "$UID_LINE" | sed 's/.*hf 14a sim -t 7 -u //')
        echo "$AMIIBO_UID" > "$KEY_FILE"
        echo " -> Success: EML and KEY files created in '$OUTPUT_DIR'"
    else
        echo " -> Error: Could not find UID. Only EML file was created." >&2
    fi
}

usage() {
    echo "Usage: $0 -f <file.bin> | -d <directory> [-t]" >&2
    echo "For more details, please see doc.md" >&2
    exit 1
}

# --- SCRIPT START ---
if ! command -v pm3_amii_bin2eml.pl &> /dev/null; then
    echo "Fatal Error: 'pm3_amii_bin2eml.pl' not found in your PATH." >&2
    exit 1
fi

TOP_LEVEL_OUTPUT=0
TARGET_FILE=""
TARGET_DIR=""

while getopts ":f:d:t" opt; do
  case $opt in
    f) TARGET_FILE="$OPTARG" ;;
    d) TARGET_DIR="$OPTARG" ;;
    t) TOP_LEVEL_OUTPUT=1 ;;
    ?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

if ([ -n "$TARGET_FILE" ] && [ -n "$TARGET_DIR" ]) || ([ -z "$TARGET_FILE" ] && [ -z "$TARGET_DIR" ]); then
    usage
fi

if [ -n "$TARGET_FILE" ]; then
    # Single File Mode
    if [ "$TOP_LEVEL_OUTPUT" -eq 1 ]; then
        echo "Warning: -t flag has no effect in single file mode (-f)." >&2
    fi
    output_dir="$(dirname "$TARGET_FILE")/eml"
    process_bin_file "$TARGET_FILE" "$output_dir"

elif [ -n "$TARGET_DIR" ]; then
    # Directory Mode
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Directory not found at '$TARGET_DIR'" >&2
        exit 1
    fi

    echo "Scanning for .bin files in '$TARGET_DIR'...'"
    if [ "$TOP_LEVEL_OUTPUT" -eq 1 ]; then
        central_output_dir="$TARGET_DIR/eml"
        echo "Output Mode: Centralized -> '$central_output_dir'"
        find "$TARGET_DIR" -type f -name "*.bin" | while read -r file; do
            process_bin_file "$file" "$central_output_dir"
        done
    else
        echo "Output Mode: Localized (next to each source file)"
        find "$TARGET_DIR" -type f -name "*.bin" | while read -r file; do
            local_output_dir="$(dirname "$file")/eml"
            process_bin_file "$file" "$local_output_dir"
        done
    fi
    echo "Directory processing complete."
fi
