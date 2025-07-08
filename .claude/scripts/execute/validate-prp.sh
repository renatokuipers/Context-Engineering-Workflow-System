#!/bin/bash

# validate-prp.sh - Validate PRP file and required inputs
# This script validates the PRP file path and ensures all required template files exist

PRP_PATH="$1"

# Function to display usage
usage() {
    echo "Usage: $0 <prp_file_path>"
    echo "  prp_file_path: Path to the PRP file to validate"
    exit 1
}

# Function to validate PRP file exists and is readable
validate_prp_file() {
    local prp_path="$1"
    
    if [[ -z "$prp_path" ]]; then
        echo "ERROR: No PRP file specified"
        usage
    fi
    
    if [[ ! -f "$prp_path" ]]; then
        echo "ERROR: PRP file not found: $prp_path"
        echo "Please check the file path and ensure the file exists."
        exit 1
    fi
    
    if [[ ! -r "$prp_path" ]]; then
        echo "ERROR: PRP file is not readable: $prp_path"
        echo "Please check file permissions."
        exit 1
    fi
    
    # Check if file is empty
    if [[ ! -s "$prp_path" ]]; then
        echo "ERROR: PRP file is empty: $prp_path"
        exit 1
    fi
    
    echo "✓ PRP file validation successful: $prp_path"
}

# Function to validate required template files
validate_template_files() {
    local required_files=(
        "PRPs/templates/prp_base.md"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo "ERROR: Required template file not found: $file"
            echo "Please ensure the template structure is properly set up."
            exit 1
        fi
        
        if [[ ! -r "$file" ]]; then
            echo "ERROR: Template file is not readable: $file"
            echo "Please check file permissions."
            exit 1
        fi
        
        if [[ ! -s "$file" ]]; then
            echo "ERROR: Template file is empty: $file"
            exit 1
        fi
    done
    
    echo "✓ Template files validation successful"
}

# Function to validate optional files
validate_optional_files() {
    local optional_files=(
        "INITIAL.md"
    )
    
    for file in "${optional_files[@]}"; do
        if [[ -f "$file" ]]; then
            if [[ ! -r "$file" ]]; then
                echo "WARNING: Optional file exists but is not readable: $file"
            else
                echo "✓ Optional file found: $file"
            fi
        else
            echo "ℹ Optional file not found: $file (this is okay)"
        fi
    done
}

# Function to validate PRP file content structure
validate_prp_content() {
    local prp_path="$1"
    
    # Check if file contains basic markdown structure
    if ! grep -q "^#" "$prp_path"; then
        echo "WARNING: PRP file may not contain proper markdown headers"
    fi
    
    # Check file size (warn if too large)
    local file_size=$(stat -c%s "$prp_path" 2>/dev/null || stat -f%z "$prp_path" 2>/dev/null)
    if [[ "$file_size" -gt 1048576 ]]; then  # 1MB
        echo "WARNING: PRP file is quite large (${file_size} bytes). This may cause processing issues."
    fi
    
    echo "✓ PRP content validation complete"
}

# Function to export validated paths for other scripts
export_validated_paths() {
    local prp_path="$1"
    
    # Convert to absolute path
    local abs_prp_path=$(realpath "$prp_path")
    
    # Export for use by other scripts
    export PRP_PATH="$abs_prp_path"
    export PRP_BASE_PATH="$(realpath "PRPs/templates/prp_base.md")"
    
    if [[ -f "INITIAL.md" ]]; then
        export INITIAL_PATH="$(realpath "INITIAL.md")"
    else
        export INITIAL_PATH=""
    fi
    
    echo "✓ Paths exported for subsequent scripts"
}

# Function to log validation results
log_validation() {
    local prp_path="$1"
    local log_file="workspace/workflow/validation.log"
    
    # Create workflow directory if it doesn't exist
    mkdir -p workspace/workflow
    
    # Log validation results
    {
        echo "[$(date)] PRP Validation Started"
        echo "PRP File: $prp_path"
        echo "PRP Base Template: PRPs/templates/prp_base.md"
        echo "Initial File: ${INITIAL_PATH:-"Not found"}"
        echo "Validation Status: SUCCESS"
        echo "---"
    } >> "$log_file"
    
    echo "✓ Validation logged to: $log_file"
}

# Main validation function
main() {
    local prp_path="$1"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PRP VALIDATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate PRP file
    validate_prp_file "$prp_path"
    
    # Validate template files
    validate_template_files
    
    # Validate optional files
    validate_optional_files
    
    # Validate PRP content
    validate_prp_content "$prp_path"
    
    # Export validated paths
    export_validated_paths "$prp_path"
    
    # Log validation
    log_validation "$prp_path"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PRP VALIDATION COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi