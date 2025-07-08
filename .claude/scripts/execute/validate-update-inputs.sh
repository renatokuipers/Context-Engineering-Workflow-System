#!/bin/bash

# validate-update-inputs.sh - Validate inputs for state update process
# This script validates agent number and required files for the update-state workflow

AGENT_NUM="$1"

# Function to display usage
usage() {
    echo "Usage: $0 <agent_number>"
    echo "  agent_number: The number of the agent that just completed (positive integer)"
    exit 1
}

# Function to validate agent number format
validate_agent_number() {
    local agent_num="$1"
    
    if [[ -z "$agent_num" ]]; then
        echo "ERROR: No agent number provided"
        usage
    fi
    
    if [[ ! "$agent_num" =~ ^[0-9]+$ ]]; then
        echo "ERROR: Agent number must be a positive integer"
        echo "Provided: $agent_num"
        exit 1
    fi
    
    if [[ "$agent_num" -lt 1 ]]; then
        echo "ERROR: Agent number must be greater than 0"
        echo "Provided: $agent_num"
        exit 1
    fi
    
    echo "✓ Agent number validated: $agent_num"
}

# Function to validate required workflow files exist
validate_workflow_files() {
    echo "📁 Validating workflow files..."
    
    local required_files=(
        "workspace/workflow/progress.md"
        "workspace/workflow/dependencies.md"
        "workspace/workflow/tasks.md"
        "workspace/workflow/execution.log"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "ERROR: Missing required workflow files:"
        printf "  - %s\n" "${missing_files[@]}"
        echo ""
        echo "These files should have been created during workflow initialization."
        echo "Please run the complete workflow initialization first."
        exit 1
    fi
    
    echo "✓ All required workflow files exist"
}

# Function to validate workflow files are readable and writable
validate_file_permissions() {
    echo "🔐 Validating file permissions..."
    
    local files_to_check=(
        "workspace/workflow/progress.md"
        "workspace/workflow/dependencies.md"
        "workspace/workflow/tasks.md"
        "workspace/workflow/execution.log"
    )
    
    for file in "${files_to_check[@]}"; do
        if [[ ! -r "$file" ]]; then
            echo "ERROR: Cannot read file: $file"
            echo "Please check file permissions."
            exit 1
        fi
        
        if [[ ! -w "$file" ]]; then
            echo "ERROR: Cannot write to file: $file"
            echo "Please check file permissions."
            exit 1
        fi
    done
    
    echo "✓ File permissions validated"
}

# Function to validate tasks.md contains the specified task
validate_task_exists() {
    local agent_num="$1"
    
    echo "📋 Validating task $agent_num exists..."
    
    if ! grep -q "^## Task $agent_num:" workspace/workflow/tasks.md; then
        echo "ERROR: Task $agent_num not found in workspace/workflow/tasks.md"
        echo ""
        echo "Available tasks:"
        grep "^## Task [0-9]\+:" workspace/workflow/tasks.md | head -5 || echo "  No tasks found"
        echo ""
        echo "Please ensure workspace/workflow/tasks.md is properly created with numbered tasks."
        exit 1
    fi
    
    echo "✓ Task $agent_num exists in workspace/workflow/tasks.md"
}

# Function to check if environment variables are available
validate_environment() {
    echo "🔧 Validating environment variables..."
    
    # Try to load environment from workflow file if it exists
    if [[ -f "workspace/workflow/environment.sh" ]]; then
        source workspace/workflow/environment.sh
        echo "✓ Environment loaded from workspace/workflow/environment.sh"
    else
        echo "ℹ workspace/workflow/environment.sh not found, using default values"
    fi
    
    # Set defaults if not available
    export PROJECT_TYPE="${PROJECT_TYPE:-generic}"
    export LANGUAGE="${LANGUAGE:-Generic}"
    export FILE_EXTENSIONS="${FILE_EXTENSIONS:-*}"
    export DEPENDENCIES_FILE="${DEPENDENCIES_FILE:-dependencies.txt}"
    export WORKSPACE_PATH="${WORKSPACE_PATH:-workspace/src}"
    
    echo "✓ Environment variables configured"
}

# Function to validate that previous tasks are properly tracked
validate_task_sequence() {
    local agent_num="$1"
    
    echo "🔍 Validating task sequence..."
    
    # If this is not task 1, check that previous tasks exist and are tracked
    if [[ "$agent_num" -gt 1 ]]; then
        local prev_task=$((agent_num - 1))
        
        # Check if previous task exists in tasks.md
        if ! grep -q "^## Task $prev_task:" workspace/workflow/tasks.md; then
            echo "WARNING: Previous task (Task $prev_task) not found in tasks.md"
            echo "This could indicate a task numbering issue."
        fi
        
        # Check if we have any record of previous task completion
        if ! grep -q "Task $prev_task" workspace/workflow/progress.md; then
            echo "WARNING: No progress record found for Task $prev_task"
            echo "This could indicate missing state updates."
        fi
    fi
    
    echo "✓ Task sequence validated"
}

# Function to create backup of current state files
create_state_backup() {
    local agent_num="$1"
    local backup_dir="workspace/workflow/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    echo "💾 Creating state backup..."
    
    mkdir -p "$backup_dir"
    
    local backup_files=(
        "workspace/workflow/progress.md"
        "workspace/workflow/dependencies.md"
    )
    
    for file in "${backup_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "${backup_dir}/$(basename "$file").backup_agent${agent_num}_${timestamp}"
        fi
    done
    
    echo "✓ State backup created in $backup_dir"
}

# Function to log validation start
log_validation_start() {
    local agent_num="$1"
    
    {
        echo "[$(date)] State update validation started for Agent $agent_num"
        echo "[$(date)] Validating inputs and workflow files"
    } >> workspace/workflow/execution.log
    
    echo "✓ Validation logged"
}

# Function to export validated variables for other scripts
export_validated_environment() {
    local agent_num="$1"
    
    # Export agent number for subsequent scripts
    export AGENT_NUM="$agent_num"
    
    # Export all environment variables
    export PROJECT_TYPE LANGUAGE FILE_EXTENSIONS DEPENDENCIES_FILE WORKSPACE_PATH
    
    echo "✓ Environment exported for subsequent scripts"
}

# Main validation function
main() {
    local agent_num="$1"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "UPDATE VALIDATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate agent number
    validate_agent_number "$agent_num"
    
    # Validate workflow files exist
    validate_workflow_files
    
    # Validate file permissions
    validate_file_permissions
    
    # Validate environment
    validate_environment
    
    # Validate task exists
    validate_task_exists "$agent_num"
    
    # Validate task sequence
    validate_task_sequence "$agent_num"
    
    # Create state backup
    create_state_backup "$agent_num"
    
    # Log validation start
    log_validation_start "$agent_num"
    
    # Export environment for other scripts
    export_validated_environment "$agent_num"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "UPDATE VALIDATION COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi