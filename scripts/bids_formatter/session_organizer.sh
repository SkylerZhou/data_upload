#!/usr/bin/env bash
# session_organizer.sh - Organizes EDF/XML files into BIDS sessions based on age

source "$(dirname "$0")/../../lib/common_functions.sh"

organize_sessions() {
    local temp_patient_dir="$1"  # e.g., temp/4ZHY
    local output_dir="$2"        # e.g., output/PRV-001
    local patient_id="$3"        # e.g., 4ZHY
    
    # Get the dataset name and subject ID from stored files
    local dataset_name
    local subject_id
    
    if [[ -f "$temp_patient_dir/.dataset_name" ]]; then
        dataset_name=$(cat "$temp_patient_dir/.dataset_name")
        subject_id=$(cat "$temp_patient_dir/.subject_id")
    else
        log_error "Missing dataset information files in $temp_patient_dir"
        return 1
    fi
    
    log "Organizing sessions for $subject_id (patient: $patient_id)"
    
    # Extract ages from all EDF files
    local -a ages=()
    local -a edf_files=()
    for edf_file in "$temp_patient_dir"/*.edf; do
        [ -f "$edf_file" ] || continue
        local filename=$(basename "$edf_file" .edf)
        # Extract age from PRV-XXX-XXXX-AGE pattern (remove any trailing letters)
        local age=$(echo "$filename" | rev | cut -d'-' -f1 | rev | sed 's/[A-Za-z]*$//')
        ages+=("$age")
        edf_files+=("$edf_file")
    done
    
    # Sort ages numerically to find baseline (smallest)
    IFS=$'\n' sorted_ages=($(printf '%s\n' "${ages[@]}" | sort -n))
    unset IFS
    
    local baseline_age="${sorted_ages[0]}"
    log "Detected baseline age: $baseline_age"
    
    # Create sessions.tsv file for the subject
    create_sessions_tsv "$output_dir" "$subject_id" "${ages[@]}"
    
    # Create sessions
    for age in "${ages[@]}"; do
        if [ "$age" = "$baseline_age" ]; then
            local session_name="ses-baseline-${age}"
        else
            local session_name="ses-followup-${age}"
        fi
        
        log "Creating session: $session_name"
        create_session_structure "$output_dir" "$subject_id" "$session_name" "$age" "$dataset_name"
        
        # Copy EDF and XML files
        copy_session_files "$temp_patient_dir" "$output_dir" "$subject_id" "$age" "$session_name" "$dataset_name"
    done
}

create_sessions_tsv() {
    local output_dir="$1"
    local subject_id="$2"
    shift 2
    local ages=("$@")
    
    local sessions_file="$output_dir/primary/$subject_id/${subject_id}_sessions.tsv"
    
    # Create sessions.tsv header
    echo -e "session_id\tage" > "$sessions_file"
    
    # Sort ages and add entries
    IFS=$'\n' sorted_ages=($(printf '%s\n' "${ages[@]}" | sort -n))
    unset IFS
    
    local baseline_age="${sorted_ages[0]}"
    
    for age in "${sorted_ages[@]}"; do
        if [ "$age" = "$baseline_age" ]; then
            echo -e "ses-baseline-${age}\t${age}" >> "$sessions_file"
        else
            echo -e "ses-followup-${age}\t${age}" >> "$sessions_file"
        fi
    done
    
    log "Created sessions file: ${subject_id}_sessions.tsv"
}

create_session_structure() {
    local output_dir="$1"
    local subject_id="$2"
    local session_name="$3"
    local age="$4"
    local dataset_name="$5"
    
    local session_path="$output_dir/primary/$subject_id/$session_name"
    
    # Create session folders
    mkdir -p "$session_path/eeg"
    mkdir -p "$session_path/anat"
    mkdir -p "$session_path/phenotype"
    
    # Create anat directory but don't add README
    mkdir -p "$session_path/anat"
    
    # Create visit_description.json for phenotype
    cat > "$session_path/phenotype/visit_description.json" <<EOF
{
    "session_id": "$session_name",
    "age_at_visit": $age,
    "visit_type": "$(if [[ $session_name == *baseline* ]]; then echo "baseline"; else echo "followup"; fi)",
    "description": "EEG recording session for subject $subject_id at age $age"
}
EOF
    
    log "  ✓ Created session structure: $session_name"
}

copy_session_files() {
    local temp_dir="$1"
    local output_dir="$2"
    local subject_id="$3"
    local age="$4"
    local session_name="$5"
    local dataset_name="$6"
    
    local session_eeg_path="$output_dir/primary/$subject_id/$session_name/eeg"
    
    # Find matching EDF file for this age (account for possible suffix like "24A")
    local edf_source=$(find "$temp_dir" -name "*-${age}*.edf" -type f | head -1)
    if [ -f "$edf_source" ]; then
        local new_edf_name="sub-${dataset_name}-${age}.edf"
        cp "$edf_source" "$session_eeg_path/$new_edf_name"
        log "  ✓ Copied EDF: $new_edf_name"
    fi
    
    # Find matching XML file for this age (account for possible suffix like "24A")
    local xml_source=$(find "$temp_dir" -name "*-${age}*-annotations.xml" -type f | head -1)
    if [ -f "$xml_source" ]; then
        local new_xml_name="sub-${dataset_name}-${age}.xml"
        cp "$xml_source" "$session_eeg_path/$new_xml_name"
        log "  ✓ Copied XML: $new_xml_name"
    fi
    
    # Create BIDS sidecar files
    create_sidecar_files "$session_eeg_path" "$dataset_name" "$age"
}

create_sidecar_files() {
    local eeg_path="$1"
    local dataset_name="$2"
    local age="$3"
    
    # Create _eeg.json sidecar
    cat > "$eeg_path/sub-${dataset_name}-${age}_task-rest_eeg.json" <<EOF
{
    "TaskName": "rest",
    "TaskDescription": "Resting state EEG recording",
    "InstitutionName": "PREVeNT Study",
    "InstitutionAddress": "n/a",
    "SamplingFrequency": "n/a",
    "EEGChannelCount": "n/a",
    "RecordingDuration": "n/a",
    "RecordingType": "continuous",
    "EEGReference": "n/a",
    "PowerLineFrequency": 50,
    "SoftwareFilters": "n/a"
}
EOF

    # Create _channels.tsv
    cat > "$eeg_path/sub-${dataset_name}-${age}_task-rest_channels.tsv" <<EOF
name	type	units	low_cutoff	high_cutoff	reference	group	sampling_frequency	description
n/a	EEG	µV	n/a	n/a	n/a	n/a	n/a	Electrode information to be populated from EDF file
EOF

    log "  ✓ Created BIDS sidecar files for sub-$dataset_name-$age"
}

# Call main function if script is executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    organize_sessions "$@"
fi