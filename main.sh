#!/usr/bin/env bash
set -euo pipefail


# pseudocode 
source lib/common_functions.sh

INPUT_DIR="$1"
PATIENT_CSV="patient_identifiers.csv"

while IFS= read -r patient_id; do
    log "Processing patient: $patient_id"
    
    # Step 1: Extract files
    ./scripts/file_organizer.sh "$INPUT_DIR" "$patient_id"
    
    # Step 2: Create BIDS structure
    ./scripts/bids_formatter/folder_structure.sh "temp/$patient_id" "output/PRV-$patient_id"
    
    # Step 3: Generate sidecars
    ./scripts/sidecar_generator/sidecar_main.sh "output/PRV-$patient_id"
    
    # Step 4: Validate
    ./scripts/validator.sh "output/PRV-$patient_id"
    
    # Step 5: Upload
    if [ $? -eq 0 ]; then
        ./scripts/upload.sh "output/PRV-$patient_id" "$patient_id"
    fi
    
    # Cleanup
    rm -rf "temp/$patient_id"
done < "$PATIENT_CSV"