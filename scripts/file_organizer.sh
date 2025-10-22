#!/usr/bin/env bash
set -euo pipefail

# OVERVIEW:
# For each patient_id in patient_identifiers.csv:
# 1. Find all files matching PRV-*-{patient_id}-* pattern
# 2. Copy to temp/{patient_id}/ folder
# 3. Validate pairs (each EDF has its corresponding XML)

source "$(dirname "$0")/../lib/common_functions.sh"

organize_files_for_patient() {
    local input_dir="$1"
    local patient_id="$2"
        
    # Create temp directory for this patient
    local temp_dir="temp/$patient_id"
    mkdir -p "$temp_dir"
    
    # Find all EDF files matching PRV-*-{patient_id}-* pattern
    local edf_files=()
    local xml_files=()
        
    # Find EDF files
    while IFS= read -r -d '' edf_file; do
        edf_files+=("$edf_file")
        log "   Found EDF: $(basename "$edf_file")"
    done < <(find "$input_dir" -name "PRV-*-${patient_id}-*.edf" -print0 2>/dev/null || true)
    
    # Find XML annotation files  
    while IFS= read -r -d '' xml_file; do
        xml_files+=("$xml_file")
        log "   Found XML: $(basename "$xml_file")"
    done < <(find "$input_dir" -name "PRV-*-${patient_id}-*-annotations.xml" -print0 2>/dev/null || true)
    
    # Check if we found any files
    if [[ ${#edf_files[@]} -eq 0 ]]; then
        log "   No EDF files found for patient $patient_id"
        return 1
    fi
    
    # Copy EDF files to temp directory
    local copied_edf_count=0
    for edf_file in "${edf_files[@]}"; do
        if [[ -f "$edf_file" ]]; then
            cp "$edf_file" "$temp_dir/"
            ((copied_edf_count++))
        fi
    done
    
    # Copy XML files to temp directory
    local copied_xml_count=0
    for xml_file in "${xml_files[@]}"; do
        if [[ -f "$xml_file" ]]; then
            cp "$xml_file" "$temp_dir/"
            ((copied_xml_count++))
        fi
    done
    
    # Return success with file counts (store in global variables for access in main)
    COPIED_EDF_COUNT=$copied_edf_count
    COPIED_XML_COUNT=$copied_xml_count
    return 0
}


# Main function
main() {
    
    local input_dir="$1"
    local patient_id="$2"
    
    # Validate input directory exists
    if [[ ! -d "$input_dir" ]]; then
        log "[ERROR]: Input directory does not exist: $input_dir"
        exit 1
    fi
    
    # Create temp directory if it doesn't exist
    mkdir -p temp
    
    # Organize files for the patient
    if organize_files_for_patient "$input_dir" "$patient_id"; then
        log "Successfully moved $COPIED_EDF_COUNT EDF and $COPIED_XML_COUNT XML files to temp/ folder for patient $patient_id"
    else
        log "[ERROR]: File organization failed for patient $patient_id"
        #exit 1
    fi
}

# Run main function with all arguments
main "$@"
