#!/usr/bin/env bash

validate_file_pairs() {
    local temp_dir="$1"
    local patient_id="$2"
    
    local unpaired_files=()
    
    for edf_file in "$temp_dir"/*.edf; do
        [ -f "$edf_file" ] || continue
        
        local base=$(basename "$edf_file" .edf)
        local xml_file="$temp_dir/${base}-annotations.xml"
        
        if [ ! -f "$xml_file" ]; then
            unpaired_files+=("$edf_file (missing XML)")
        fi
    done
    
    if [ ${#unpaired_files[@]} -gt 0 ]; then
        log "⚠️  WARNING: Unpaired files found:"
        printf '  - %s\n' "${unpaired_files[@]}"
        return 1
    fi
    
    return 0
}

validate_age_format() {
    local age="$1"
    
    # Age can be numeric (10, 24) or alphanumeric (18A, 24A)
    if [[ ! "$age" =~ ^[0-9]+[A-Z]?$ ]]; then
        log "❌ Invalid age format: $age"
        return 1
    fi
    
    return 0
}