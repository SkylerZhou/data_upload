# lib/common_functions.sh

# Initialize logging
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/pipeline.log"
QUIET_MODE="${QUIET:-1}"  # Default to quiet mode (1), set QUIET=0 for verbose

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Unified logging function - handles all log types with configurable behavior
log_message() {
    local level="$1"
    local message="$2"
    local force_show="${3:-0}"  # Optional: force show in terminal even in quiet mode
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp]"
    
    # Add level prefix if provided
    if [[ -n "$level" && "$level" != "INFO" ]]; then
        log_entry="$log_entry $level: $message"
    else
        log_entry="$log_entry $message"
    fi
    
    # Always write to log file
    echo "$log_entry" >> "$LOG_FILE"
    
    # Terminal output logic
    case "$level" in
        "ERROR"|"WARNING")
            # Always show errors and warnings to stderr
            echo "$log_entry" >&2
            ;;
        "PROGRESS")
            # Progress shows brief message even in quiet mode
            echo "$message"
            ;;
        *)
            # Regular logs only show if not in quiet mode or force_show is set
            if [[ "$QUIET_MODE" != "1" || "$force_show" == "1" ]]; then
                echo "$log_entry"
            fi
            ;;
    esac
}

# Convenience wrapper functions for backward compatibility
log() {
    log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

log_success() {
    log_message "SUCCESS" "$1"
}

log_progress() {
    log_message "PROGRESS" "$1"
}

# Debug logging function (only shows if DEBUG=1)
log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        local message="$1"
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local log_entry="[$timestamp] DEBUG: $message"
        
        echo "$log_entry" >> "$LOG_FILE"
        echo "$log_entry" >&2
    fi
}

# Function to get current log file path
get_log_file() {
    echo "$LOG_FILE"
}

# Function to add session separator to log
start_log_session() {
    local session_start=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" >> "$LOG_FILE"
    echo "===============================================" >> "$LOG_FILE"
    echo "NEW SESSION STARTED: $session_start" >> "$LOG_FILE"
    echo "===============================================" >> "$LOG_FILE"
}

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