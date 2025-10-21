#!/usr/bin/env python3
"""
F11 Form Parser for PREVeNT Study

This module handles parsing of F11 forms to extract metadata for BIDS sidecars.
Different sidecar generators can request different fields from the same F11 form.

TODO: Implement actual F11 form parsing based on form structure
"""

import os
from pathlib import Path
from typing import Dict, List, Optional, Any


class F11Parser:
    """Parser for F11 forms with field-specific extraction methods"""
    
    def __init__(self, f11_data_directory: Optional[str] = None):
        """
        Initialize F11 parser
        
        Args:
            f11_data_directory: Directory containing F11 forms/data
        """
        self.f11_data_directory = f11_data_directory or self._find_f11_directory()
        self.cached_data = {}  # Cache parsed data to avoid re-parsing
    
    def _find_f11_directory(self) -> Optional[str]:
        """
        Auto-detect F11 data directory
        
        Returns:
            Path to F11 directory or None if not found
            
        TODO: Implement logic to find F11 forms location
        """
        # TODO: Define where F11 forms are stored
        # Possibilities: 
        # - resources/ folder
        # - separate F11 data directory
        # - database/API endpoint
        return None
    
    def get_patient_f11_data(self, patient_id: str) -> Dict[str, Any]:
        """
        Get all F11 data for a specific patient
        
        Args:
            patient_id: Patient identifier (e.g., "13UL")
            
        Returns:
            Dictionary containing all F11 data for the patient
            
        TODO: Implement actual F11 data retrieval
        """
        if patient_id in self.cached_data:
            return self.cached_data[patient_id]
        
        # TODO: Implement F11 data loading
        # This could be:
        # - Reading from Excel/CSV files
        # - Querying a database
        # - Parsing structured forms
        
        # Placeholder structure based on common F11 sections
        f11_data = {
            "demographics": {
                "age": None,
                "sex": None,
                "handedness": None,
                "date_of_birth": None
            },
            "recording_parameters": {
                "task_description": "resting state EEG",
                "institution": None,
                "equipment_manufacturer": None,
                "equipment_model": None,
                "sampling_rate": None,
                "recording_duration": None
            },
            "clinical_info": {
                "diagnosis": None,
                "medications": None,
                "clinical_notes": None
            },
            "study_info": {
                "visit_date": None,
                "visit_type": None,
                "protocol_version": None
            }
        }
        
        # Cache the data
        self.cached_data[patient_id] = f11_data
        return f11_data
    
    def extract_for_eeg_json(self, patient_id: str) -> Dict[str, Any]:
        """
        Extract F11 fields specifically needed for EEG JSON sidecars
        
        Args:
            patient_id: Patient identifier
            
        Returns:
            Dictionary with fields needed for EEG JSON
        """
        f11_data = self.get_patient_f11_data(patient_id)
        
        return {
            "task_description": f11_data["recording_parameters"]["task_description"],
            "institution": f11_data["recording_parameters"]["institution"],
            "equipment_manufacturer": f11_data["recording_parameters"]["equipment_manufacturer"],
            "equipment_model": f11_data["recording_parameters"]["equipment_model"],
            "sampling_rate": f11_data["recording_parameters"]["sampling_rate"],
            "recording_duration": f11_data["recording_parameters"]["recording_duration"]
        }
    
    def extract_for_participants_tsv(self, patient_id: str) -> Dict[str, Any]:
        """
        Extract F11 fields specifically needed for participants.tsv
        
        Args:
            patient_id: Patient identifier
            
        Returns:
            Dictionary with fields needed for participants.tsv
        """
        f11_data = self.get_patient_f11_data(patient_id)
        
        return {
            "age": f11_data["demographics"]["age"],
            "sex": f11_data["demographics"]["sex"],
            "handedness": f11_data["demographics"]["handedness"]
        }
    
    def extract_for_sessions_tsv(self, patient_id: str) -> Dict[str, Any]:
        """
        Extract F11 fields specifically needed for sessions.tsv
        
        Args:
            patient_id: Patient identifier
            
        Returns:
            Dictionary with fields needed for sessions.tsv
        """
        f11_data = self.get_patient_f11_data(patient_id)
        
        return {
            "visit_date": f11_data["study_info"]["visit_date"],
            "visit_type": f11_data["study_info"]["visit_type"],
            "protocol_version": f11_data["study_info"]["protocol_version"]
        }
    
    def extract_custom_fields(self, patient_id: str, field_list: List[str]) -> Dict[str, Any]:
        """
        Extract specific fields requested by a sidecar generator
        
        Args:
            patient_id: Patient identifier
            field_list: List of field paths (e.g., ["demographics.age", "recording_parameters.institution"])
            
        Returns:
            Dictionary with requested fields
        """
        f11_data = self.get_patient_f11_data(patient_id)
        result = {}
        
        for field_path in field_list:
            value = self._get_nested_field(f11_data, field_path)
            # Use the last part of the path as the key
            field_name = field_path.split('.')[-1]
            result[field_name] = value
        
        return result
    
    def _get_nested_field(self, data: Dict, field_path: str) -> Any:
        """
        Get a nested field from the F11 data using dot notation
        
        Args:
            data: The F11 data dictionary
            field_path: Dot-separated path (e.g., "demographics.age")
            
        Returns:
            Field value or None if not found
        """
        parts = field_path.split('.')
        current = data
        
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return None
        
        return current


# Convenience function for easy importing
def extract_from_f11_form(patient_id: str, extraction_type: str = "eeg_json") -> Dict[str, Any]:
    """
    Convenience function for F11 extraction
    
    Args:
        patient_id: Patient identifier
        extraction_type: Type of extraction ("eeg_json", "participants_tsv", "sessions_tsv", or "custom")
        
    Returns:
        Extracted F11 data
    """
    parser = F11Parser()
    
    if extraction_type == "eeg_json":
        return parser.extract_for_eeg_json(patient_id)
    elif extraction_type == "participants_tsv":
        return parser.extract_for_participants_tsv(patient_id)
    elif extraction_type == "sessions_tsv":
        return parser.extract_for_sessions_tsv(patient_id)
    else:
        # For custom extractions, return all data
        return parser.get_patient_f11_data(patient_id)


# For testing
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python f11_parser.py <patient_id>")
        print("Example: python f11_parser.py 13UL")
        sys.exit(1)
    
    patient_id = sys.argv[1]
    
    print(f"Testing F11 parser for patient: {patient_id}")
    print("\n=== EEG JSON Fields ===")
    eeg_data = extract_from_f11_form(patient_id, "eeg_json")
    for key, value in eeg_data.items():
        print(f"{key}: {value}")
    
    print("\n=== Participants TSV Fields ===")
    participants_data = extract_from_f11_form(patient_id, "participants_tsv")
    for key, value in participants_data.items():
        print(f"{key}: {value}")
