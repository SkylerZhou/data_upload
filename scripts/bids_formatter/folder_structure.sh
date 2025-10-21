#!/usr/bin/env bash
# folder_structure.sh - Main BIDS structure creator

source "$(dirname "$0")/../../lib/common_functions.sh"
load_yaml_config "config/bids_structure.yaml"

create_bids_structure() {
    local temp_patient_dir="$1"
    local output_root="$2"  # e.g., output/
    local patient_id="$3"
    
    local dataset_name="PRV-${patient_id}"
    local output_dir="$output_root/$dataset_name"
    
    log "Creating BIDS structure for: $dataset_name"
    
    # Create root-level files
    mkdir -p "$output_dir"
    
    # Create derivatives structure (but don't populate yet)
    mkdir -p "$output_dir/derivatives/preprocessed"
    create_placeholder_structure "$output_dir/derivatives/juriaan_mri" \
        "MRI data will be added by neuroimaging pipeline"
    
    # Create primary structure
    mkdir -p "$output_dir/primary/sub-PRV-${patient_id}"
    
    # Organize sessions (calls session_organizer.sh)
    ./scripts/bids_formatter/session_organizer.sh "$temp_patient_dir" "$output_dir" "$patient_id"
    
    log "✓ BIDS structure created successfully"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    create_bids_structure "$@"
fi