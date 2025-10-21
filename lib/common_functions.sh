# lib/common_functions.sh

create_placeholder_structure() {
    local dir="$1"
    local note="$2"
    
    mkdir -p "$dir"
    
    # Create README to indicate future population
    cat > "$dir/README.txt" <<EOF
This folder will be populated by a separate pipeline.
Status: PENDING
Note: $note
Created: $(date '+%Y-%m-%d %H:%M:%S')
EOF
}

is_folder_populated() {
    local dir="$1"
    # Returns 0 (true) if folder has files other than README
    [ -d "$dir" ] && [ "$(find "$dir" -type f ! -name 'README.txt' | wc -l)" -gt 0 ]
}