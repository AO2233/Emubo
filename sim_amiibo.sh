#!/bin/bash
# Simulates an Amiibo with Proxmark3, handling state saves.
set -e
set -o pipefail

# --- Color Definitions ---
C_RED='[0;31m'
C_YELLOW='[1;33m'
C_GREEN='[0;32m'
C_BLUE='[0;34m'
C_NC='[0m' # No Color

# --- Log Helpers ---
msg_error() { echo -e "${C_RED}Error: $1${C_NC}"; }
msg_warning() { echo -e "${C_YELLOW}Warning: $1${C_NC}"; }
msg_info() { echo -e "${C_BLUE}Info: $1${C_NC}"; }
msg_success() { echo -e "${C_GREEN}Success: $1${C_NC}"; }

usage() {
  echo "Usage: $0 [-n] <path_to_amiibo_file>" >&2
  echo "For more details, please see README.md" >&2
  exit 1
}

main() {
  local new_amiibo_flag=0
  while getopts "nh" opt; do
    case ${opt} in
      n) new_amiibo_flag=1 ;;
      h) usage ;;
      ?) usage ;;
    esac
  done
  shift $((OPTIND -1))

  # --- Prerequisite and Argument Checks ---
  if ! command -v pm3 &> /dev/null; then
    msg_error "'pm3' command not found. Ensure it is installed and in your PATH."
    exit 1
  fi
  if [ -z "$1" ]; then
    msg_error "No file path provided."
    usage
  fi

  # --- Path Resolution ---
  local input_path="$1"
  if [ ! -f "$input_path" ]; then
      msg_error "Input path is not a valid file: '$input_path'"
      usage
  fi
  
  local dir_path
  dir_path=$(dirname "$input_path")
  dir_path=$(cd "$dir_path" && pwd) # Resolve to absolute path

  local filename
  filename=$(basename "$input_path")
  local amiibo_name
  amiibo_name="${filename%.*}"

  msg_info "Resolved Amiibo: '$amiibo_name' | Directory: '$dir_path'"

  # --- File Definitions ---
  local eml_file="${dir_path}/${amiibo_name}.eml"
  local key_file="${dir_path}/${amiibo_name}.key"
  local bin_file="${dir_path}/${amiibo_name}.bin"

  # --- Determine Load File ---
  local load_file=""
  local load_source_message=""
  if [ "$new_amiibo_flag" -eq 1 ]; then
    load_file="$eml_file"
    load_source_message="EML (Forced New)"
  elif [ -f "$bin_file" ]; then
    load_file="$bin_file"
    load_source_message="BIN (Existing Data)"
  else
    msg_warning "Saved data ('$bin_file') not found. Falling back to new Amiibo."
    load_file="$eml_file"
    load_source_message="EML (Fallback)"
  fi

  # --- Pre-run Checks ---
  if [ ! -f "$key_file" ]; then
    msg_error "Required key file not found: '$key_file'"
    exit 1
  fi
  if [ ! -f "$load_file" ]; then
    msg_error "Data file to load not found: '$load_file'"
    exit 1
  fi
  local uid
  uid=$(<"$key_file")
  if [ -z "$uid" ]; then
    msg_error "Key file '$key_file' is empty or unreadable."
    exit 1
  fi

  # --- Execute Simulation ---
  echo
  msg_info "Preparing for Amiibo Simulation"
  echo "  Amiibo: $amiibo_name"
  echo "  Source: $load_file ($load_source_message)"
  echo "  UID:    $uid"
  echo
  msg_warning "--> ACTION REQUIRED <--"
  msg_warning "Press the button on the Proxmark3 to stop simulation and save."
  echo

  # Load, simulate, and save data.
  pm3 -c "hf mfu eload -f "$load_file"" >/dev/null
  pm3 -c "hf mfu sim -t 7 -u "$uid"" >/dev/null
  
  # Save data safely to a temporary file first.
  msg_info "Saving data..."
  local temp_file_base="${bin_file}.tmp"
  local actual_temp_bin="${temp_file_base}.bin"
  rm -f "${actual_temp_bin}" # Clean up old temp file
  
  local pm3_save_output
  pm3_save_output=$(pm3 -c "hf mfu esave -f "$temp_file_base"" 2>&1)

  # --- Post-run Confirmation ---
  if [[ "$pm3_save_output" == *"Saved to"* && -f "$actual_temp_bin" ]]; then
    mv "$actual_temp_bin" "$bin_file"
    # Also move the .json if it was created
    [ -f "${temp_file_base}.json" ] && mv "${temp_file_base}.json" "${bin_file}.json"
    echo
    msg_success "Simulation finished. Memory saved to '$bin_file'"
  else
    rm -f "${temp_file_base}.*" # Clean up any failed temp files
    echo
    msg_error "Save process failed. Original data was not modified."
    msg_warning "Please check Proxmark3 output for details."
  fi
}

main "$@"
