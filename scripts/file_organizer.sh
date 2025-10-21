#!/bin/bash

# OVERVIEW:
# For each patient_id in patient_identieifer.csv:
# 1. Find all files matching PRV-*-{patient_id}-* pattern
# 2. Copy to temp/{patient_id}/ folder
# 3. Validate pairs (each EDF has its corresponding XML)

