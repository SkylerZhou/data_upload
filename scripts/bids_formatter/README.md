# BIDS Formatter

This directory contains scripts to convert organized EDF/XML files into BIDS (Brain Imaging Data Structure) format for the PREVeNT study.

## Overview

The BIDS formatter transforms patient data from the temporary organization structure into a standardized BIDS-compliant format that looks like this:

```
output/
├── PRV-1W4Y/                          # Dataset per patient identifier
│   ├── dataset_description.json      # BIDS dataset metadata
│   ├── participants.json             # Participant metadata schema
│   ├── participants.tsv              # Participant information
│   ├── derivatives/                  # Processed data
│   │   ├── preprocessed/
│   │   └── juriaan_mri/             # (populated later)
│   └── primary/                      # Raw data
│       └── sub-PRV-1W4Y/            # Subject directory
│           ├── sub-PRV-1W4Y_sessions.tsv
│           ├── ses-baseline-24/      # Baseline session (smallest age)
│           │   ├── eeg/
│           │   │   ├── sub-PRV-1W4Y-24.edf
│           │   │   ├── sub-PRV-1W4Y-24.xml
│           │   │   ├── sub-PRV-1W4Y-24_task-rest_eeg.json
│           │   │   └── sub-PRV-1W4Y-24_task-rest_channels.tsv
│           │   ├── anat/            # (populated later)
│           │   └── phenotype/
│           │       └── visit_description.json
│           ├── ses-followup-18/     # Follow-up sessions
│           └── ses-followup-24/
```

## Scripts

### `bids_main.sh` - Main orchestrator
Main entry point that processes all patients from the CSV file.

**Usage:**
```bash
./scripts/bids_formatter/bids_main.sh temp/ output/ patient_identifiers.csv
```

### `folder_structure.sh` - Directory structure creator
Creates the BIDS folder hierarchy and metadata files for a single patient.

### `session_organizer.sh` - Session handler
Organizes EDF/XML files into age-based sessions (baseline vs. follow-up).

## Features

1. **Automatic Dataset Naming**: Extracts patient codes (PRV-001, PRV-002, etc.) from filenames
2. **Age-Based Sessions**: 
   - Baseline session: Uses the smallest age found
   - Follow-up sessions: All other ages
3. **BIDS Compliance**: Creates proper JSON sidecars and TSV files
4. **Error Handling**: Continues processing even if individual patients fail
5. **Summary Reporting**: Generates a completion report

## File Naming Convention

Input files follow the pattern: `PRV-XXX-YYYY-ZZ.edf` and `PRV-XXX-YYYY-ZZ-annotations.xml`

Where:
- `PRV-XXX`: Dataset/patient code (e.g., PRV-001)
- `YYYY`: Patient ID (e.g., 4ZHY)
- `ZZ`: Age (e.g., 15, 18, 24)

Output follows BIDS naming:
- EDF files: `PRV-XXX-ZZ_task-rest_eeg.edf`
- XML files: `PRV-XXX-ZZ.xml`
- JSON sidecars: `PRV-XXX-ZZ_task-rest_eeg.json`
- Channel files: `PRV-XXX-ZZ_task-rest_channels.tsv`

## Running the Formatter

1. Ensure temp/ directory contains organized patient files
2. Run the main formatter:
   ```bash
   cd data_upload/
   ./scripts/bids_formatter/bids_main.sh temp/ output/ patient_identifiers.csv
   ```
3. Check the output/ directory for BIDS-formatted datasets
4. Review the summary report: `output/BIDS_formatting_summary.txt`

## Output Structure Details

- **Multiple Datasets**: Each unique PRV-XXX code gets its own dataset directory
- **Session Organization**: Age-based sessions with proper baseline identification
- **Placeholder Directories**: `anat/` and `juriaan_mri/` created but left empty for future population
- **BIDS Metadata**: Complete JSON and TSV files for BIDS compliance
- **Compatibility Files**: Both BIDS-named and original-pattern files for flexibility

## Troubleshooting

- Check log files in `logs/pipeline.log` for detailed processing information
- Use `QUIET=0` environment variable for verbose output
- Missing patients in temp/ will be skipped with warnings
- Individual patient failures don't stop overall processing