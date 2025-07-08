#!/bin/bash

# prepare-next-agent.sh - Prepare for next agent deployment
# This script determines if the workflow is ready for the next agent and prepares deployment

# This ensures all paths are resolved correctly, no matter where the script is called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script prepares for next agent deployment using environment variables set by validation phase"
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
    
    echo "✓ Environment variables validated for next agent preparation"
}

# Function to check remaining tasks in workspace/workflow/tasks.md
check_remaining_tasks() {
    local current_agent="$1"
    
    echo "📋 Checking remaining tasks..."
    
    local remaining_tasks=()
    local next_task_num=$((current_agent + 1))
    local total_tasks=0
    local completed_tasks=0
    
    # Count total tasks
    total_tasks=$(grep -c "^## Task [0-9]\+:" workspace/workflow/tasks.md 2>/dev/null || echo "0")
    
    # Count completed tasks by checking progress.md
    for ((i=1; i<=current_agent; i++)); do
        if grep -q "Task $i.*COMPLETE" workspace/workflow/progress.md 2>/dev/null; then
            ((completed_tasks++))
        fi
    done
    
    echo "  📊 Progress: $completed_tasks/$total_tasks tasks completed"
    
    # Find remaining tasks
    for ((i=next_task_num; i<=total_tasks; i++)); do
        if grep -q "^## Task $i:" workspace/workflow/tasks.md 2>/dev/null; then
            local task_title=$(sed -n "/^## Task $i:/p" workspace/workflow/tasks.md | sed "s/## Task $i: //")
            remaining_tasks+=("Task $i: $task_title")
        fi
    done
    
    if [[ ${#remaining_tasks[@]} -gt 0 ]]; then
        echo "  📋 Remaining tasks:"
        printf "    - %s\n" "${remaining_tasks[@]}"
        echo "  ➡️  Next task: Task $next_task_num"
    else
        echo "  ✅ All tasks completed!"
        export ALL_TASKS_COMPLETE="true"
    fi
    
    export NEXT_TASK_NUM="$next_task_num"
    export REMAINING_TASK_COUNT="${#remaining_tasks[@]}"
    
    echo "✓ Task analysis completed"
}

# Function to identify available imports for next agent
identify_available_imports() {
    local current_agent="$1"
    
    echo "🔗 Identifying available imports for next agent..."
    
    local available_imports=()
    
    # Collect exports from all completed agents
    for ((i=1; i<=current_agent; i++)); do
        if grep -q "## Agent $i Exports" workspace/workflow/dependencies.md 2>/dev/null; then
            # Extract the export section for this agent
            local exports=$(sed -n "/^## Agent $i Exports/,/^## /p" workspace/workflow/dependencies.md | grep -E "^- |^  - " | head -10)
            if [[ -n "$exports" ]]; then
                available_imports+=("From Agent $i:")
                while IFS= read -r line; do
                    available_imports+=("  $line")
                done <<< "$exports"
                available_imports+=("")
            fi
        fi
    done
    
    if [[ ${#available_imports[@]} -gt 0 ]]; then
        echo "  📦 Available imports for next agent:"
        printf "    %s\n" "${available_imports[@]}"
    else
        echo "  ℹ️  No documented exports available yet"
    fi
    
    echo "✓ Available imports identified"
}

# Function to check for blocking issues
check_blocking_issues() {
    local current_agent="$1"
    
    echo "🚫 Checking for blocking issues..."
    
    local blocking_issues=()
    
    # Check if current task was marked as incomplete
    if grep -q "Task $current_agent.*INCOMPLETE\|Task $current_agent.*FAILED" workspace/workflow/progress.md 2>/dev/null; then
        blocking_issues+=("Task $current_agent marked as incomplete or failed")
    fi
    
    # Check for known issues in dependencies.md
    if grep -q "## Known Issues" workspace/workflow/dependencies.md 2>/dev/null; then
        local issues=$(sed -n "/^## Known Issues/,/^## /p" workspace/workflow/dependencies.md | grep -E "^- " | head -5)
        if [[ -n "$issues" ]]; then
            blocking_issues+=("Known issues documented:")
            while IFS= read -r line; do
                blocking_issues+=("  $line")
            done <<< "$issues"
        fi
    fi
    
    # Check for file structure violations from previous validation
    if [[ -f "workspace/workflow/file-structure-agent-${current_agent}.md" ]]; then
        if grep -q "❌\|WARNING" "workspace/workflow/file-structure-agent-${current_agent}.md"; then
            blocking_issues+=("File structure violations detected in Agent $current_agent")
        fi
    fi
    
    # Check if required project files are missing
    case "$PROJECT_TYPE" in
        "python")
            if [[ ! -f "workspace/requirements.txt" ]]; then
                blocking_issues+=("Missing required file: workspace/requirements.txt")
            fi
            ;;
        "nodejs")
            if [[ ! -f "workspace/package.json" ]]; then
                blocking_issues+=("Missing required file: workspace/package.json")
            fi
            ;;
        "rust")
            if [[ ! -f "workspace/Cargo.toml" ]]; then
                blocking_issues+=("Missing required file: workspace/Cargo.toml")
            fi
            ;;
        "go")
            if [[ ! -f "workspace/go.mod" ]]; then
                blocking_issues+=("Missing required file: workspace/go.mod")
            fi
            ;;
    esac
    
    if [[ ${#blocking_issues[@]} -gt 0 ]]; then
        echo "  ⚠️  Blocking issues found:"
        printf "    - %s\n" "${blocking_issues[@]}"
        export HAS_BLOCKING_ISSUES="true"
    else
        echo "  ✅ No blocking issues detected"
        export HAS_BLOCKING_ISSUES="false"
    fi
    
    echo "✓ Blocking issues check completed"
}

# Function to mark current task as complete in workspace/workflow/tasks.md
mark_task_complete() {
    local current_agent="$1"
    
    echo "✅ Marking Task $current_agent as COMPLETE in workspace/workflow/tasks.md..."
    
    # Update the task in tasks.md to show completion
    local temp_file=$(mktemp)
    local task_updated=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]Task[[:space:]]${current_agent}: ]]; then
            echo "## Task $current_agent: COMPLETE - $(basename "$line" | sed 's/^## Task [0-9]*: //')" >> "$temp_file"
            task_updated=true
        else
            echo "$line" >> "$temp_file"
        fi
    done < workspace/workflow/tasks.md
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/tasks.md
    
    if [[ "$task_updated" == true ]]; then
        echo "  ✓ Task $current_agent marked as COMPLETE"
    else
        echo "  ⚠️  Task $current_agent not found or already marked"
    fi
    
    echo "✓ Task completion marking completed"
}

# Function to generate next steps
generate_next_steps() {
    local current_agent="$1"
    
    echo "🚀 Generating next steps..."
    
    if [[ "$ALL_TASKS_COMPLETE" == "true" ]]; then
        cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 ALL TASKS COMPLETE - WORKFLOW FINISHED! 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Sequential execution finished successfully!

## Final Steps:
1. **Run Build**: ${BUILD_COMMAND:-"Project-specific build command"}
2. **Run Tests**: ${TYPE_CHECK_COMMAND:-"Project-specific test command"}  
3. **Verify Integration**: Check all components work together
4. **Review Documentation**: Ensure all exports are documented

## Project Summary:
- **Type**: $PROJECT_TYPE
- **Language**: $LANGUAGE  
- **workspace**: $WORKSPACE_PATH
- **Total Tasks**: Completed all tasks successfully

🎯 **Implementation Complete!**
EOF
    elif [[ "$HAS_BLOCKING_ISSUES" == "true" ]]; then
        cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  BLOCKING ISSUES DETECTED ⚠️
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🛑 **Cannot proceed to next agent until issues are resolved**

## Required Actions:
1. Review and resolve all blocking issues listed above
2. Ensure Task $current_agent is properly completed  
3. Fix any file structure violations
4. Verify all required project files exist

## Once Issues Are Resolved:
Run: \`.claude/scripts/execute/deploy-agent.sh $NEXT_TASK_NUM\`
EOF
    else
        cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 READY FOR NEXT AGENT DEPLOYMENT 🚀
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ **Agent $current_agent completed successfully**
✅ **No blocking issues detected**  
✅ **Ready to proceed with Task $NEXT_TASK_NUM**

## Deploy Next Agent:
\`.claude/scripts/execute/deploy-agent.sh $NEXT_TASK_NUM\`

## Progress:
- **Completed**: $current_agent tasks
- **Remaining**: $REMAINING_TASK_COUNT tasks
- **Next**: Task $NEXT_TASK_NUM

## Available for Next Agent:
$(identify_available_imports "$current_agent" 2>&1 | grep -E "📦|From Agent" | sed 's/^//')
EOF
    fi
}

# Function to create next agent preparation report
create_preparation_report() {
    local current_agent="$1"
    
    echo "📊 Creating next agent preparation report..."
    
    local report_file="workspace/workflow/next-agent-preparation.md"
    
    cat > "$report_file" << EOF
# Next Agent Preparation Report

**Date**: $(date)
**Current Agent**: $current_agent
**Project Type**: $PROJECT_TYPE
**Language**: $LANGUAGE

## Task Analysis
$(check_remaining_tasks "$current_agent" 2>&1)

## Available Imports
$(identify_available_imports "$current_agent" 2>&1)

## Blocking Issues Check
$(check_blocking_issues "$current_agent" 2>&1)

## Next Steps
$(generate_next_steps "$current_agent" 2>&1)

## Workflow Status
- **All Tasks Complete**: ${ALL_TASKS_COMPLETE:-false}
- **Has Blocking Issues**: ${HAS_BLOCKING_ISSUES:-false}
- **Next Task Number**: ${NEXT_TASK_NUM:-"N/A"}
- **Remaining Tasks**: ${REMAINING_TASK_COUNT:-0}

## Files Status
- Progress tracking: workspace/workflow/progress.md ✓
- Dependencies tracking: workspace/workflow/dependencies.md ✓  
- Task definitions: workspace/workflow/tasks.md ✓
- Execution log: workspace/workflow/execution.log ✓
EOF
    
    echo "✓ Preparation report created: $report_file"
}

# Function to log next agent preparation
log_preparation() {
    local current_agent="$1"
    
    {
        echo "[$(date)] Next agent preparation completed for Agent $current_agent"
        echo "[$(date)] All tasks complete: ${ALL_TASKS_COMPLETE:-false}"
        echo "[$(date)] Has blocking issues: ${HAS_BLOCKING_ISSUES:-false}"
        echo "[$(date)] Next task number: ${NEXT_TASK_NUM:-N/A}"
    } >> workspace/workflow/execution.log
    
    echo "✓ Next agent preparation logged"
}

# Main next agent preparation function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NEXT AGENT PREPARATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root: $PROJECT_ROOT"
    
    # Validate environment
    validate_environment
    
    echo "🔄 Preparing for next agent after Agent $AGENT_NUM..."
    echo "🔧 Project Type: $PROJECT_TYPE"
    echo "💻 Language: $LANGUAGE"
    echo "📁 workspace: $WORKSPACE_PATH"
    
    # Perform preparation analysis
    check_remaining_tasks "$AGENT_NUM"
    identify_available_imports "$AGENT_NUM"
    check_blocking_issues "$AGENT_NUM"
    mark_task_complete "$AGENT_NUM"
    
    # Generate next steps and report
    create_preparation_report "$AGENT_NUM"
    generate_next_steps "$AGENT_NUM"
    
    # Log the preparation
    log_preparation "$AGENT_NUM"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NEXT AGENT PREPARATION COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi