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


def map_fields_from_sources(source_data_dict, field_mapping_config):
    """
    Map fields from source data based on configuration
    
    Args:
        source_data_dict (dict): All available source data {"edf": {...}, "f11": {...}}
        field_mapping_config (list): Configuration defining which fields to use
        
    Returns:
        dict: Mapped fields for BIDS JSON
        
    Example config:
    sources:
      - source: "edf_header"
        field_mapping:
          "SamplingFrequency": "sampling_frequency"
          "EEGChannelCount": "number_of_channels"
      - source: "f11_form"  
        field_mapping:
          "TaskName": "task_description"
          "InstitutionName": "institution"
    """
    mapped_fields = {}
    
    for source_config in field_mapping_config:
        source_name = source_config.get("source")
        field_mapping = source_config.get("field_mapping", {})
        
        # Map source names to our data keys
        source_key_mapping = {
            "edf_header": "edf",
            "f11_form": "f11", 
            "xml_annotations": "xml"
        }
        
        source_key = source_key_mapping.get(source_name)
        if source_key and source_key in source_data_dict:
            source_data = source_data_dict[source_key]
            
            for bids_field, source_field in field_mapping.items():
                if source_field in source_data:
                    mapped_fields[bids_field] = source_data[source_field]
                    print(f"✅ Mapped {bids_field} = {source_data[source_field]} (from {source_name}.{source_field})")
                else:
                    print(f"⚠️  Field {source_field} not found in {source_name} data")
    
    return mapped_fields


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
    
    # Extract ALL available data from sources (comprehensive extraction)
    try:
        edf_metadata = extract_from_edf_header(edf_file_path)  # Gets ALL EDF fields
        f11_metadata = extract_from_f11_form(patient_id)       # Gets ALL F11 fields
        
        # Get field mapping configuration for EEG JSON
        eeg_field_config = eeg_config.get('sources', [])
        print(f"📋 Available EDF fields: {list(edf_metadata.keys())}")
        print(f"📋 Available F11 fields: {list(f11_metadata.keys())}")
        
    except Exception as e:
        print(f"⚠️  Warning: Error extracting metadata: {e}")
        print("   Using placeholder values")
        edf_metadata = {"sampling_frequency": None, "recording_duration": None, "number_of_channels": None}
        f11_metadata = {"task_description": None, "institution": None, "equipment_manufacturer": None}
    
    # Combine all source data for field mapping
    all_source_data = {
        "edf": edf_metadata,
        "f11": f11_metadata
        # "xml": xml_metadata  # TODO: Add when XML parser is implemented
    }
    
    # Map fields based on configuration (if available)
    mapped_fields = {}
    if eeg_config and 'sources' in eeg_config:
        mapped_fields = map_fields_from_sources(all_source_data, eeg_config['sources'])
    
    # Create the BIDS-compliant EEG JSON structure
    # Use mapped fields when available, fall back to direct access for now
    eeg_json = {
        # Required fields - try mapped first, then direct access
        "TaskName": mapped_fields.get("TaskName", f11_metadata.get("task_description", "rest")),
        "SamplingFrequency": mapped_fields.get("SamplingFrequency", edf_metadata.get("sampling_frequency")),
        
        # Recommended fields  
        "PowerLineFrequency": mapped_fields.get("PowerLineFrequency", 60),  # TODO: Get from config or F11
        "SoftwareFilters": mapped_fields.get("SoftwareFilters", "n/a"),     # TODO: Get from EDF or F11
        
        # Optional fields that may be available
        "RecordingDuration": mapped_fields.get("RecordingDuration", edf_metadata.get("recording_duration")),
        "RecordingType": mapped_fields.get("RecordingType", "continuous"),
        "EEGReference": mapped_fields.get("EEGReference", edf_metadata.get("reference", "")),
        "EEGGround": mapped_fields.get("EEGGround", edf_metadata.get("ground", "")),
        
        # Institution and equipment info
        "InstitutionName": mapped_fields.get("InstitutionName", f11_metadata.get("institution")),
        "InstitutionAddress": mapped_fields.get("InstitutionAddress", f11_metadata.get("institution_address", "")),
        "Manufacturer": mapped_fields.get("Manufacturer", f11_metadata.get("equipment_manufacturer")),
        "ManufacturersModelName": mapped_fields.get("ManufacturersModelName", f11_metadata.get("equipment_model")),
        "SoftwareVersions": mapped_fields.get("SoftwareVersions", edf_metadata.get("software_version", "")),
        
        # Subject and session info
        "SubjectArtefactDescription": mapped_fields.get("SubjectArtefactDescription", ""),
        
        # Additional metadata
        "HowManyBadChannels": mapped_fields.get("HowManyBadChannels", 0),
        "EEGChannelCount": mapped_fields.get("EEGChannelCount", edf_metadata.get("number_of_channels")),
        
        # Development info (remove when fully implemented)
        "_dev_info": {
            "note": "Field mapping system active - remove this section when fully implemented",
            "mapped_fields_used": list(mapped_fields.keys()),
            "available_edf_fields": list(edf_metadata.keys()),
            "available_f11_fields": list(f11_metadata.keys())
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