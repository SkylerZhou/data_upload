#!/usr/bin/env python3
"""
EEG JSON sidecar generator for BIDS format

This script generates the *_task-rest_eeg.json sidecar files required by BIDS.
Currently creates skeleton files with empty/placeholder values.

TODO: Implement actual data extraction from:
- EDF headers (sampling frequency, recording duration, etc.)
- F11 forms (task description, institution, equipment info)
- XML annotations (if needed for task-specific metadata)
"""

import json
import os
import sys
import yaml
from pathlib import Path

# Import extractors
sys.path.append(str(Path(__file__).parent.parent / "extractors"))
from edf_header_parser import extract_from_edf_header
from f11_parser import extract_from_f11_form


def load_configs():
    """Load both BIDS structure and sidecar configuration files"""
    # Get the script directory and navigate to config folder
    script_dir = Path(__file__).parent.parent.parent.parent
    config_dir = script_dir / "config"
    
    structure_config_path = config_dir / "bids_structure.yaml"
    sidecar_config_path = config_dir / "sidecar_config.yaml"
    
    try:
        with open(structure_config_path, 'r') as f:
            structure_config = yaml.safe_load(f)
        with open(sidecar_config_path, 'r') as f:
            sidecar_config = yaml.safe_load(f)
        return structure_config, sidecar_config
    except FileNotFoundError as e:
        print(f"Error: Configuration file not found: {e}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"Error: Invalid YAML configuration: {e}")
        sys.exit(1)


def create_eeg_json(output_path, edf_file_path, patient_id, session_age):
    """
    Generate EEG JSON sidecar file
    
    Args:
        output_path (str): Where to save the JSON file
        edf_file_path (str): Source EDF file path
        patient_id (str): Patient identifier (e.g., "13UL")
        session_age (str): Session age (e.g., "24")
    """
    
    # Load configurations
    structure_config, sidecar_config = load_configs()
    eeg_config = sidecar_config['sidecars']['eeg_json']
    
    print(f"Generating EEG JSON sidecar: {output_path}")
    print(f"Source EDF: {edf_file_path}")
    print(f"Patient: {patient_id}, Session: {session_age}")
    
    # Extract data from various sources using dedicated extractors
    try:
        edf_metadata = extract_from_edf_header(edf_file_path)
        f11_metadata = extract_from_f11_form(patient_id, "eeg_json")
    except Exception as e:
        print(f"⚠️  Warning: Error extracting metadata: {e}")
        print("   Using placeholder values")
        edf_metadata = {"sampling_frequency": None, "recording_duration": None, "number_of_channels": None}
        f11_metadata = {"task_description": None, "institution": None, "equipment_manufacturer": None}
    
    # Create the BIDS-compliant EEG JSON structure
    # Based on BIDS specification for EEG data
    eeg_json = {
        # Required fields
        "TaskName": "rest",  # TODO: Get from F11 or config
        "SamplingFrequency": edf_metadata["sampling_frequency"],  # TODO: Extract from EDF
        
        # Recommended fields  
        "PowerLineFrequency": 60,  # TODO: Determine from location/equipment
        "SoftwareFilters": "n/a",  # TODO: Determine if any filters applied
        
        # Optional fields that may be available
        "RecordingDuration": edf_metadata["recording_duration"],  # TODO: Extract from EDF
        "RecordingType": "continuous",  # TODO: Verify this is correct
        "EEGReference": "",  # TODO: Extract from EDF or F11
        "EEGGround": "",  # TODO: Extract from EDF or F11
        
        # Institution and equipment info
        "InstitutionName": f11_metadata.get("institution"),  # From F11 extractor
        "InstitutionAddress": "",  # TODO: Add to F11 if available
        "Manufacturer": f11_metadata.get("equipment_manufacturer"),  # From F11 extractor  
        "ManufacturersModelName": f11_metadata.get("equipment_model"),  # From F11 extractor
        "SoftwareVersions": "",  # TODO: Extract from EDF header
        
        # Subject and session info
        "SubjectArtefactDescription": "",  # TODO: Check if available in annotations
        
        # Additional metadata
        "HowManyBadChannels": 0,  # TODO: Analyze EDF or annotations
        "EEGChannelCount": edf_metadata["number_of_channels"],  # TODO: Extract from EDF
        
        # Placeholder for future expansion
        "TODO_FIELDS": {
            "note": "These fields will be populated when data sources are implemented",
            "sources_to_implement": [
                "EDF header parsing",
                "F11 form parsing", 
                "XML annotation analysis",
                "Equipment database lookup"
            ]
        }
    }
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Write JSON file with proper formatting
    try:
        with open(output_path, 'w') as f:
            json.dump(eeg_json, f, indent=2, ensure_ascii=False)
        print(f"✅ EEG JSON sidecar created: {output_path}")
        
        # TODO: Add validation against BIDS schema
        validate_eeg_json(eeg_json, sidecar_config)
        
    except Exception as e:
        print(f"❌ Error creating EEG JSON sidecar: {e}")
        sys.exit(1)


def validate_eeg_json(eeg_json, sidecar_config):
    """
    Validate the generated EEG JSON against BIDS requirements
    
    Args:
        eeg_json (dict): The generated JSON content
        sidecar_config (dict): Configuration for validation rules
        
    TODO: Implement validation against:
    - BIDS schema requirements
    - Custom validation rules from config
    """
    required_fields = sidecar_config.get('validation', {}).get('eeg_json_required_fields', [])
    
    missing_fields = []
    for field in required_fields:
        if field not in eeg_json or eeg_json[field] is None or eeg_json[field] == "":
            missing_fields.append(field)
    
    if missing_fields:
        print(f"⚠️  Warning: Missing required fields: {missing_fields}")
        print("   These will need to be populated when data sources are implemented")
    else:
        print("✅ All required fields present (though may contain placeholder values)")


def main():
    """Main function for standalone testing"""
    if len(sys.argv) != 5:
        print("Usage: python create_eeg_json.py <output_path> <edf_file> <patient_id> <session_age>")
        print("Example: python create_eeg_json.py output/sub-PRV-13UL_task-rest_eeg.json input/PRV-002-13UL-24.edf 13UL 24")
        sys.exit(1)
    
    output_path = sys.argv[1]
    edf_file_path = sys.argv[2] 
    patient_id = sys.argv[3]
    session_age = sys.argv[4]
    
    create_eeg_json(output_path, edf_file_path, patient_id, session_age)


if __name__ == "__main__":
    main()