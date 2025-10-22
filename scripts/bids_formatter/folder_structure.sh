#!/usr/bin/env bash
# folder_structure.sh - Main BIDS structure creator

source "$(dirname "$0")/../../lib/common_functions.sh"

create_bids_structure() {
    local temp_patient_dir="$1"  # e.g., temp/4ZHY
    local patient_id="$2"        # e.g., 4ZHY
    
    # Create dataset name using PRV-patientID format (e.g., PRV-1W4Y)
    local dataset_name="PRV-${patient_id}"
    
    # Create BIDS structure directly under temp/ (not inside patient folder)
    local temp_root=$(dirname "$temp_patient_dir")  # temp/
    local bids_dir="$temp_root/$dataset_name"       # temp/PRV-1W4Y
    
    log "Creating BIDS structure for dataset: $dataset_name (patient: $patient_id)"
    
    # Create main dataset directory
    mkdir -p "$bids_dir"
    
    # Create BIDS root-level files
    create_dataset_description "$bids_dir" "$dataset_name"
    create_participants_files "$bids_dir" "$dataset_name"
    
    # Create derivatives structure
    mkdir -p "$bids_dir/derivatives/preprocessed"
    mkdir -p "$bids_dir/derivatives/preprocessed/juriaan_mri"
    
    # Create primary structure
    mkdir -p "$bids_dir/primary"
    
    # Create subject directory within primary
    local subject_id="sub-$dataset_name"
    mkdir -p "$bids_dir/primary/$subject_id"
    
    # Store paths for use by other scripts
    echo "$bids_dir" > "$temp_patient_dir/.bids_root"
    echo "$subject_id" > "$temp_patient_dir/.subject_id"
    echo "$dataset_name" > "$temp_patient_dir/.dataset_name"
    
    # Organize sessions (calls session_organizer.sh)
    ./scripts/bids_formatter/session_organizer.sh "$temp_patient_dir" "$bids_dir" "$patient_id"
    
    log "✓ BIDS structure created successfully for $dataset_name"
    
    # Clean up: Remove the original patient folder since BIDS structure is now directly under temp/
    log "Cleaning up original patient folder: $patient_id"
    rm -rf "$temp_patient_dir"
    
    log "✓ Cleanup completed - $dataset_name folder created directly under temp/"
}

create_dataset_description() {
    local output_dir="$1"
    local dataset_name="$2"
    
    cat > "$output_dir/dataset_description.json" <<EOF
{
    "Name": "$dataset_name Dataset",
    "BIDSVersion": "1.8.0",
    "DatasetType": "raw",
    "Authors": ["PREVeNT Study Team"],
    "Acknowledgements": "PREVeNT study data",
    "License": "CC0",
    "ReferencesAndLinks": [],
    "DatasetDOI": "",
    "EthicsApprovals": []
}
EOF
}

create_participants_files() {
    local output_dir="$1"
    local dataset_name="$2"
    
    # Create participants.json
    cat > "$output_dir/participants.json" <<EOF
{
    "participant_id": {
        "Description": "Unique participant identifier"
    },
    "age": {
        "Description": "Age of the participant at baseline",
        "Units": "years"
    },
    "sex": {
        "Description": "Sex of the participant",
        "Levels": {
            "M": "male",
            "F": "female"
        }
    }
}
EOF

    # Create participants.tsv
    cat > "$output_dir/participants.tsv" <<EOF
participant_id	age	sex
sub-$dataset_name	n/a	n/a
EOF
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    create_bids_structure "$@"
fi