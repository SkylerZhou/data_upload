#!/bin/bash

# Extract age from filename: PRV-002-13UL-24 → session age is "24"
# Determine if baseline or followup 
# Create: ses-baseline-24/ or ses-followup-24/

#!/usr/bin/env bash
# session_organizer.sh

source "$(dirname "$0")/../../lib/common_functions.sh"

organize_sessions() {
    local temp_patient_dir="$1"
    local output_dir="$2"
    local patient_id="$3"
    
    log "Organizing sessions for patient: $patient_id"
    
    # Extract ages from all EDF files
    local -a ages=()
    for edf_file in "$temp_patient_dir"/*.edf; do
        [ -f "$edf_file" ] || continue
        local filename=$(basename "$edf_file" .edf)
        # Extract age from PRV-XXX-XXXX-AGE pattern
        local age=$(echo "$filename" | awk -F'-' '{print $NF}')
        ages+=("$age")
    done
    
    # Sort ages to find baseline (smallest)
    IFS=$'\n' sorted_ages=($(sort -V <<<"${ages[*]}"))
    unset IFS
    
    local baseline_age="${sorted_ages[0]}"
    log "Detected baseline age: $baseline_age"
    
    # Create sessions
    for age in "${ages[@]}"; do
        if [ "$age" = "$baseline_age" ]; then
            local session_name="ses-baseline-${age}"
        else
            local session_name="ses-followup-${age}"
        fi
        
        log "Creating session: $session_name"
        create_session_structure "$output_dir" "$patient_id" "$session_name" "$age"
        
        # Copy EDF and XML files
        copy_session_files "$temp_patient_dir" "$output_dir" "$patient_id" "$age" "$session_name"
    done
}

create_session_structure() {
    local output_dir="$1"
    local patient_id="$2"
    local session_name="$3"
    local age="$4"
    
    local session_path="$output_dir/primary/sub-PRV-${patient_id}/${session_name}"
    
    # Create folder structure from config
    mkdir -p "$session_path/eeg"
    mkdir -p "$session_path/anat"  # Create but leave empty
    mkdir -p "$session_path/phenotype"
    
    log "  ✓ Created session structure: $session_name"
}

copy_session_files() {
    local temp_dir="$1"
    local output_dir="$2"
    local patient_id="$3"
    local age="$4"
    local session_name="$5"
    
    local session_eeg_path="$output_dir/primary/sub-PRV-${patient_id}/${session_name}/eeg"
    
    # Find matching EDF file
    local edf_source=$(find "$temp_dir" -name "PRV-*-${patient_id}-${age}.edf" -type f | head -1)
    if [ -f "$edf_source" ]; then
        cp "$edf_source" "$session_eeg_path/sub-PRV-${patient_id}-${age}.edf"
        log "  ✓ Copied EDF: sub-PRV-${patient_id}-${age}.edf"
    fi
    
    # Find matching XML file
    local xml_source=$(find "$temp_dir" -name "PRV-*-${patient_id}-${age}-annotations.xml" -type f | head -1)
    if [ -f "$xml_source" ]; then
        cp "$xml_source" "$session_eeg_path/sub-PRV-${patient_id}-${age}.xml"
        log "  ✓ Copied XML: sub-PRV-${patient_id}-${age}.xml"
    fi
}

# Call main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    organize_sessions "$@"
fi