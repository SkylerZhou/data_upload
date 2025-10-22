#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# PREVeNT BIDS Data Processing Pipeline
# =============================================================================
# This script processes EEG data files and organizes them into BIDS format
# for the PREVeNT study.
#
# Usage: ./main.sh <input_directory>
# Example: ./main.sh input/
#
# The script will:
# 1. Read patient identifiers from patient_identifiers.csv
# 2. For each patient, organize their EDF/XML files into temp folders
# 3. Create BIDS-compliant folder structure directly in temp/
# 4. Generate required sidecar files (TODO)
# 5. Validate the BIDS structure (TODO)
# 6. Upload to Pennsieve (TODO)
# =============================================================================



# ==== SETUP AND VALIDATION ===================================================
source lib/common_functions.sh

INPUT_DIR="$1"
PATIENT_CSV="patient_identifiers.csv"

# Validate inputs
if [[ ! -d "$INPUT_DIR" ]]; then
    log_error "Input directory does not exist: $INPUT_DIR"
    exit 1
fi

if [[ ! -f "$PATIENT_CSV" ]]; then
    log_error "Patient CSV file not found: $PATIENT_CSV"
    exit 1
fi



# ==== LOGGING SETUP ===========================================================
# Start new log session
start_log_session
echo ""

# Count total patients
TOTAL_PATIENTS=$(grep -v '^patient_identifier' "$PATIENT_CSV" | wc -l | tr -d ' ')
echo "Processing $TOTAL_PATIENTS patients from $INPUT_DIR"
echo ""

# Log session start info
log "Total patients to process: $TOTAL_PATIENTS"
log "" 

CURRENT_PATIENT=0
SUCCESSFUL_PATIENTS=0
FAILED_PATIENTS=0



# ==== MAIN PROCESSING LOOP ===================================================
while IFS=, read -r patient_id _; do
    # Skip header row
    if [[ "$patient_id" == "patient_identifier" ]]; then
        continue
    fi
    
    CURRENT_PATIENT=$((CURRENT_PATIENT + 1))
    
    # Display progress in terminal
    log_progress "[$CURRENT_PATIENT/$TOTAL_PATIENTS] Processing: $patient_id"
    
    # STEP 1: Extract files
    if ./scripts/file_organizer.sh "$INPUT_DIR" "$patient_id"; then
        
        # STEP 2: Create BIDS structure directly in temp directory
        if ./scripts/bids_formatter/folder_structure.sh "temp/$patient_id" "$patient_id"; then
            log "✓ BIDS formatting completed for patient $patient_id"
            SUCCESSFUL_PATIENTS=$((SUCCESSFUL_PATIENTS + 1))
        else
            log_error "BIDS formatting failed for patient $patient_id"
            FAILED_PATIENTS=$((FAILED_PATIENTS + 1))
        fi
        
        # TODO: Uncomment these steps as they are implemented
        # ./scripts/sidecar_generator/sidecar_main.sh "temp/$patient_id/PRV-$patient_id"
        # ./scripts/bids_validator.sh "temp/$patient_id/PRV-$patient_id"
        # ./scripts/upload.sh "temp/$patient_id/PRV-$patient_id" "$patient_id"
        
        # Skip cleanup for now to inspect results
        # rm -rf "temp/$patient_id"
        
    else
        FAILED_PATIENTS=$((FAILED_PATIENTS + 1))
    fi
        
done < "$PATIENT_CSV"



# ==== FINAL SUMMARY ======================================================
# Log final summary to file
log "FINAL SUMMARY: Processed $CURRENT_PATIENT patients. Success: $SUCCESSFUL_PATIENTS, Failed: $FAILED_PATIENTS"