#!/bin/bash

# update-state.sh - Main coordinator for state update workflow
# This script coordinates all phases of the state update process after agent completion

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

AGENT_NUM="$1"

# Function to display usage
usage() {
    echo "Usage: $0 <agent_number>"
    echo "  agent_number: The number of the agent that just completed (positive integer)"
    echo ""
    echo "This script coordinates the complete state update workflow by running:"
    echo "  1. Input validation phase"
    echo "  2. Progress update phase"
    echo "  3. Dependencies update phase"
    echo "  4. Integration analysis phase"
    echo "  5. File structure validation phase"
    echo "  6. Next agent preparation phase"
    exit 1
}

# Function to check if a phase script exists and is executable
check_phase_script() {
    local script_path="$1"
    local phase_name="$2"
    
    if [[ ! -f "$script_path" ]]; then
        echo "ERROR: ${phase_name} script not found: $script_path"
        exit 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        echo "ERROR: ${phase_name} script is not executable: $script_path"
        echo "Run: chmod +x $script_path"
        exit 1
    fi
}

# Function to run a phase and check for success
run_phase() {
    local script_path="$1"
    local phase_name="$2"
    local args="${3:-}"
    
    echo ""
    echo "🔄 Starting ${phase_name}..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ -n "$args" ]]; then
        "$PROJECT_ROOT/$script_path" "$args"
    else
        "$PROJECT_ROOT/$script_path"
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "ERROR: ${phase_name} failed with exit code: $exit_code"
        echo "Aborting state update workflow."
        exit $exit_code
    fi
    
    echo "✓ ${phase_name} completed successfully"
    echo ""
}

# Function to validate all required phase scripts
validate_phase_scripts() {
    echo "🔍 Validating phase scripts..."
    
    local scripts=(
        ".claude/scripts/execute/validate-update-inputs.sh:Input Validation"
        ".claude/scripts/execute/update-progress.sh:Progress Update"
        ".claude/scripts/execute/update-dependencies.sh:Dependencies Update"
        ".claude/scripts/execute/analyze-integration.sh:Integration Analysis"
        ".claude/scripts/execute/validate-file-structure.sh:File Structure Validation"
        ".claude/scripts/execute/prepare-next-agent.sh:Next Agent Preparation"
    )
    
    for script_info in "${scripts[@]}"; do
        IFS=':' read -r script_path phase_name <<< "$script_info"
        check_phase_script "$PROJECT_ROOT/$script_path" "$phase_name"
    done
    
    echo "✓ All phase scripts validated"
}

# Function to create master state update log
create_master_log() {
    local agent_num="$1"
    local log_file="workspace/workflow/master-state-update.log"
    
    {
        echo "========================================"
        echo "MASTER STATE UPDATE LOG"
        echo "========================================"
        echo "Started: $(date)"
        echo "Agent Number: $agent_num"
        echo "Working Directory: $(pwd)"
        echo "User: $(whoami)"
        echo "========================================"
        echo ""
    } >> "$log_file"
    
    echo "📝 Master state update log updated: $log_file"
}

# Function to log phase completion
log_phase_completion() {
    local phase_name="$1"
    local log_file="workspace/workflow/master-state-update.log"
    
    {
        echo "[$(date)] PHASE COMPLETED: $phase_name"
    } >> "$log_file"
}

# Function to finalize state update log
finalize_state_update_log() {
    local agent_num="$1"
    local log_file="workspace/workflow/master-state-update.log"
    
    {
        echo ""
        echo "========================================"
        echo "STATE UPDATE COMPLETED FOR AGENT $agent_num"
        echo "========================================"
        echo "Completed: $(date)"
        echo "Status: SUCCESS"
        echo "Next Step: Check next-agent-preparation.md for next steps"
        echo "========================================"
    } >> "$log_file"
}

# Function to display final summary
display_final_summary() {
    local agent_num="$1"
    
    # Load environment to get project info
    if [[ -f "workspace/workflow/environment.sh" ]]; then
        source workspace/workflow/environment.sh >/dev/null 2>&1
    fi
    
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STATE UPDATE COMPLETE FOR AGENT $agent_num
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **Agent**: $agent_num
📁 **Project Type**: ${PROJECT_TYPE:-"Detected automatically"}
💻 **Language**: ${LANGUAGE:-"Language-specific"}

📊 **State Files Updated**:
   ✓ workspace/workflow/progress.md - Task completion tracked
   ✓ workspace/workflow/dependencies.md - Component exports documented
   ✓ workspace/workflow/execution.log - State update logged
   ✓ workspace/workflow/next-agent-preparation.md - Next steps prepared

🔍 **Analysis Completed**:
   ✓ Agent inputs validated
   ✓ Progress tracking updated
   ✓ Dependencies documented
   ✓ Integration analyzed
   ✓ File structure validated
   ✓ Next agent prepared

📋 **Next Steps**: 
Check workspace/workflow/next-agent-preparation.md for detailed next steps and deployment instructions.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# Main execution function
main() {
    local agent_num="$1"
    
    # Check if agent number is provided
    if [[ -z "$agent_num" ]]; then
        echo "ERROR: No agent number specified"
        usage
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STATE UPDATE WORKFLOW COORDINATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 Agent Number: $agent_num"
    echo "📅 Started: $(date)"
    echo "📁 Project Root: $PROJECT_ROOT"
    echo "📂 Current Working Directory: $(pwd)"
    
    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root for consistency."

    # Validate phase scripts exist
    validate_phase_scripts
    
    # Create master state update log
    create_master_log "$agent_num"
    
    # Phase 1: Input Validation
    run_phase ".claude/scripts/execute/validate-update-inputs.sh" "Phase 1: Input Validation" "$agent_num"
    log_phase_completion "Input Validation"
    
    # Source environment for subsequent phases
    if [[ -f "$PROJECT_ROOT/workspace/workflow/environment.sh" ]]; then
        source "$PROJECT_ROOT/workspace/workflow/environment.sh"
        echo "✓ Environment loaded for subsequent phases"
    fi
    
    # Export AGENT_NUM for subsequent phases
    export AGENT_NUM="$agent_num"
    
    # Phase 2: Progress Update
    run_phase ".claude/scripts/execute/update-progress.sh" "Phase 2: Progress Update"
    log_phase_completion "Progress Update"
    
    # Phase 3: Dependencies Update
    run_phase ".claude/scripts/execute/update-dependencies.sh" "Phase 3: Dependencies Update"
    log_phase_completion "Dependencies Update"
    
    # Phase 4: Integration Analysis
    run_phase ".claude/scripts/execute/analyze-integration.sh" "Phase 4: Integration Analysis"
    log_phase_completion "Integration Analysis"
    
    # Phase 5: File Structure Validation
    run_phase ".claude/scripts/execute/validate-file-structure.sh" "Phase 5: File Structure Validation"
    log_phase_completion "File Structure Validation"
    
    # Phase 6: Next Agent Preparation
    run_phase ".claude/scripts/execute/prepare-next-agent.sh" "Phase 6: Next Agent Preparation"
    log_phase_completion "Next Agent Preparation"
    
    # Finalize logs and display summary
    finalize_state_update_log "$agent_num"
    display_final_summary "$agent_num"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi