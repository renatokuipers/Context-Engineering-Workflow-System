#!/bin/bash

# update-progress.sh - Update workflow progress tracking
# This script updates workflow/progress.md with task completion status

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script updates progress tracking using environment variables set by validation phase"
    exit 1
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "AGENT_NUM"
        "PROJECT_TYPE"
        "LANGUAGE"
        "WORKSPACE_PATH"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "ERROR: Missing required environment variables:"
        printf "  - %s\n" "${missing_vars[@]}"
        echo "Please run validate-update-inputs.sh first."
        exit 1
    fi
    
    echo "✓ Environment variables validated for progress update"
}

# Function to extract task title from tasks.md
get_task_title() {
    local agent_num="$1"
    
    local task_title=$(sed -n "/^## Task $agent_num:/p" workspace/workflow/tasks.md | sed "s/## Task $agent_num: //")
    
    if [[ -z "$task_title" ]]; then
        echo "Generic Task $agent_num"
    else
        echo "$task_title"
    fi
}

# Function to extract agent summary from the last output
extract_agent_summary() {
    echo "📊 Extracting agent summary from output..."
    
    # This is a placeholder for the actual agent summary extraction
    # In a real implementation, this would parse the agent's output
    # For now, we'll create a template that Claude Code can fill in
    
    cat << EOF
[AGENT SUMMARY PLACEHOLDER]

Please replace this placeholder with the actual summary from Agent $AGENT_NUM's output.

The summary should include:
- Brief description of what was implemented
- Key components created
- Files created and their purposes
- Any important notes or decisions made

Example format:
Implemented the core data models for the application including User, Project, and Task classes. Created comprehensive validation and serialization methods. All models include proper type hints and follow ${LANGUAGE} best practices.
EOF
}

# Function to update the Agent Status section
update_agent_status() {
    local agent_num="$1"
    local task_title="$2"
    
    echo "🔄 Updating agent status section..."
    
    # Create a temporary file with the updated status
    local temp_file=$(mktemp)
    local status_updated=false
    
    while IFS= read -r line; do
        if [[ "$line" == "## Agent Status" ]]; then
            echo "$line" >> "$temp_file"
            echo "- **Task $agent_num**: COMPLETED - $(date)" >> "$temp_file"
            echo "- **Task Title**: $task_title" >> "$temp_file"
            echo "- **Status**: Waiting for next task deployment" >> "$temp_file"
            echo "" >> "$temp_file"
            status_updated=true
        elif [[ "$line" == "[Pending task extraction]" ]] && [[ "$status_updated" == false ]]; then
            # Replace the placeholder text
            echo "- **Task $agent_num**: COMPLETED - $(date)" >> "$temp_file"
            echo "- **Task Title**: $task_title" >> "$temp_file"
            echo "- **Status**: Ready for next task" >> "$temp_file"
            echo "" >> "$temp_file"
            status_updated=true
        else
            echo "$line" >> "$temp_file"
        fi
    done < workspace/workflow/progress.md
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/progress.md
    
    echo "✓ Agent status updated"
}

# Function to add task completion entry
add_task_completion() {
    local agent_num="$1"
    local task_title="$2"
    
    echo "✅ Adding task completion entry..."
    
    # Find the "## Task Progress" section and add the completion
    local temp_file=$(mktemp)
    local in_task_progress=false
    local entry_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        if [[ "$line" == "## Task Progress" ]]; then
            in_task_progress=true
        elif [[ "$in_task_progress" == true ]] && [[ "$line" =~ ^\[.*\]$ ]] && [[ "$entry_added" == false ]]; then
            # This is a placeholder line, replace it
            echo "### Task $agent_num: COMPLETE - $(date)" >> "$temp_file"
            echo "**Title**: $task_title" >> "$temp_file"
            echo "**Agent**: Agent $agent_num" >> "$temp_file"
            echo "**Status**: Implementation completed successfully" >> "$temp_file"
            echo "" >> "$temp_file"
            entry_added=true
        elif [[ "$in_task_progress" == true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ "$entry_added" == false ]]; then
            # We've hit the next section without finding a placeholder, add before this section
            echo "### Task $agent_num: COMPLETE - $(date)" >> "$temp_file"
            echo "**Title**: $task_title" >> "$temp_file"
            echo "**Agent**: Agent $agent_num" >> "$temp_file"
            echo "**Status**: Implementation completed successfully" >> "$temp_file"
            echo "" >> "$temp_file"
            entry_added=true
        fi
    done < workspace/workflow/progress.md
    
    # If we didn't add the entry yet, add it at the end
    if [[ "$entry_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "### Task $agent_num: COMPLETE - $(date)" >> "$temp_file"
        echo "**Title**: $task_title" >> "$temp_file"
        echo "**Agent**: Agent $agent_num" >> "$temp_file"
        echo "**Status**: Implementation completed successfully" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/progress.md
    
    echo "✓ Task completion entry added"
}

# Function to add completed component entry
add_completed_component() {
    local agent_num="$1"
    local task_title="$2"
    
    echo "📦 Adding completed component entry..."
    
    local agent_summary=$(extract_agent_summary)
    
    # Find the "## Completed Components" section and add the component
    local temp_file=$(mktemp)
    local in_completed_section=false
    local entry_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        if [[ "$line" == "## Completed Components" ]]; then
            in_completed_section=true
        elif [[ "$in_completed_section" == true ]] && [[ "$line" =~ ^\[.*\]$ ]] && [[ "$entry_added" == false ]]; then
            # This is a placeholder line, replace it
            echo "### Agent $agent_num Output - $task_title" >> "$temp_file"
            echo "**Completed**: $(date)" >> "$temp_file"
            echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$agent_summary" >> "$temp_file"
            echo "" >> "$temp_file"
            entry_added=true
        elif [[ "$in_completed_section" == true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ "$entry_added" == false ]]; then
            # We've hit the next section without finding a placeholder, add before this section
            echo "### Agent $agent_num Output - $task_title" >> "$temp_file"
            echo "**Completed**: $(date)" >> "$temp_file"
            echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$agent_summary" >> "$temp_file"
            echo "" >> "$temp_file"
            entry_added=true
        fi
    done < workspace/workflow/progress.md
    
    # If we didn't add the entry yet, add it at the end
    if [[ "$entry_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "### Agent $agent_num Output - $task_title" >> "$temp_file"
        echo "**Completed**: $(date)" >> "$temp_file"
        echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "$agent_summary" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/progress.md
    
    echo "✓ Completed component entry added"
}

# Function to update timeline
update_timeline() {
    local agent_num="$1"
    local task_title="$2"
    
    echo "⏰ Updating timeline..."
    
    # Find the "## Timeline" section and add the new entry
    local temp_file=$(mktemp)
    local timeline_found=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        if [[ "$line" == "## Timeline" ]]; then
            timeline_found=true
        elif [[ "$timeline_found" == true ]] && [[ "$line" =~ ^-.*Workflow\ initialized$ ]]; then
            # Add our entry after the initialization line
            echo "$line" >> "$temp_file"
            echo "- **$(date)**: Task $agent_num completed - $task_title" >> "$temp_file"
            continue
        fi
    done < workspace/workflow/progress.md
    
    # If no timeline section found, this will be handled by the original structure
    # Replace the original file
    mv "$temp_file" workspace/workflow/progress.md
    
    echo "✓ Timeline updated"
}

# Function to validate the updated progress file
validate_progress_update() {
    local agent_num="$1"
    
    echo "✅ Validating progress update..."
    
    # Check that the task completion was added
    if ! grep -q "Task $agent_num: COMPLETE" workspace/workflow/progress.md; then
        echo "WARNING: Task $agent_num completion may not have been properly recorded"
    fi
    
    # Check that the file is still readable
    if [[ ! -r workspace/workflow/progress.md ]]; then
        echo "ERROR: Progress file is no longer readable"
        exit 1
    fi
    
    echo "✓ Progress update validated"
}

# Function to log progress update
log_progress_update() {
    local agent_num="$1"
    local task_title="$2"
    
    {
        echo "[$(date)] Progress updated for Agent $agent_num"
        echo "[$(date)] Task completed: $task_title"
        echo "[$(date)] Progress tracking updated successfully"
    } >> workspace/workflow/execution.log
    
    echo "✓ Progress update logged"
}

# Main progress update function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PROGRESS UPDATE PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate environment
    validate_environment
    
    # Get task information
    local task_title=$(get_task_title "$AGENT_NUM")
    echo "📋 Processing completion for: Task $AGENT_NUM - $task_title"
    
    # Update various sections of progress.md
    update_agent_status "$AGENT_NUM" "$task_title"
    add_task_completion "$AGENT_NUM" "$task_title"
    add_completed_component "$AGENT_NUM" "$task_title"
    update_timeline "$AGENT_NUM" "$task_title"
    
    # Validate the update
    validate_progress_update "$AGENT_NUM"
    
    # Log the update
    log_progress_update "$AGENT_NUM" "$task_title"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PROGRESS UPDATE COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi