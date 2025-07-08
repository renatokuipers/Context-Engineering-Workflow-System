#!/bin/bash

# initiate-execution.sh - Main orchestrator for PRP execution workflow
# This script coordinates all phases of the workflow initialization

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0 <prp_file_path>"
    echo "  prp_file_path: Path to the PRP file to execute"
    echo ""
    echo "This script orchestrates the complete workflow initialization by running:"
    echo "  1. PRP validation phase"
    echo "  2. workspace setup phase" 
    echo "  3. Workflow initialization phase"
    echo "  4. Orchestration phase"
    exit 1
}

# Function to check if a phase script exists and is executable
check_phase_script() {
    local script_path="$1"
    local phase_name="$2"
    
    if [[ ! -f "$PROJECT_ROOT/$script_path" ]]; then
        echo "ERROR: ${phase_name} script not found: $PROJECT_ROOT/$script_path"
        exit 1
    fi
    
    if [[ ! -x "$PROJECT_ROOT/$script_path" ]]; then
        echo "ERROR: ${phase_name} script is not executable: $PROJECT_ROOT/$script_path"
        echo "Run: chmod +x $PROJECT_ROOT/$script_path"
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
    
    # Always execute scripts from the project root to ensure consistent relative paths.
    if [[ -n "$args" ]]; then
        (cd "$PROJECT_ROOT" && bash "$PROJECT_ROOT/$script_path" "$args")
    else
        (cd "$PROJECT_ROOT" && bash "$PROJECT_ROOT/$script_path")
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo "ERROR: ${phase_name} failed with exit code: $exit_code"
        echo "Aborting workflow initialization."
        exit $exit_code
    fi
    
    echo "✓ ${phase_name} completed successfully"
    echo ""
}

# Function to validate all required phase scripts
validate_phase_scripts() {
    echo "🔍 Validating phase scripts..."
    
    local scripts=(
        ".claude/scripts/execute/validate-prp.sh:PRP Validation"
        ".claude/scripts/execute/setup-workspace.sh:workspace Setup"
        ".claude/scripts/execute/initialize-workflow.sh:Workflow Initialization"
        ".claude/scripts/execute/orchestrate-execution.sh:Orchestration"
    )
    
    for script_info in "${scripts[@]}"; do
        IFS=':' read -r script_path phase_name <<< "$script_info"
        check_phase_script "$script_path" "$phase_name"
    done
    
    echo "✓ All phase scripts validated"
}

# Function to create master execution log
create_master_log() {
    local prp_path="$1"
    local log_file="$PROJECT_ROOT/workspace/workflow/master-execution.log"
    
    mkdir -p "$PROJECT_ROOT/workspace/workflow"
    
    {
        echo "========================================"
        echo "MASTER EXECUTION LOG"
        echo "========================================"
        echo "Started: $(date)"
        echo "PRP File: $prp_path"
        echo "Project Root: $PROJECT_ROOT"
        echo "User: $(whoami)"
        echo "System: $(uname -a)"
        echo "========================================"
        echo ""
    } > "$log_file"
    
    echo "📝 Master execution log created: $log_file"
}

# Function to log phase completion
log_phase_completion() {
    local phase_name="$1"
    local log_file="$PROJECT_ROOT/workspace/workflow/master-execution.log"
    
    {
        echo "[$(date)] PHASE COMPLETED: $phase_name"
    } >> "$log_file"
}

# Function to finalize execution log
finalize_execution_log() {
    local log_file="$PROJECT_ROOT/workspace/workflow/master-execution.log"
    
    {
        echo ""
        echo "========================================"
        echo "WORKFLOW INITIALIZATION COMPLETED"
        echo "========================================"
        echo "Completed: $(date)"
        echo "Status: SUCCESS"
        echo "Next Step: Create workspace/workflow/tasks.md and deploy first agent"
        echo "========================================"
    } >> "$log_file"
}

# Function to display final summary
display_final_summary() {
    local prp_path="$1"
    
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WORKFLOW INITIALIZATION COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 **PRP File**: $prp_path
📁 **Project Type**: ${PROJECT_TYPE:-"Detected automatically"}
💻 **Language**: ${LANGUAGE:-"Language-specific"}
🏗️  **workspace**: ${WORKSPACE_PATH:-"Project structure created"}

📊 **Workflow Files Created**:
   ✓ workspace/workflow/progress.md - Task progress tracking
   ✓ workspace/workflow/dependencies.md - Component dependencies  
   ✓ workspace/workflow/execution.log - Detailed execution log
   ✓ workspace/workflow/tasks.template.md - Task creation template
   ✓ workspace/workflow/environment.sh - Environment variables
   ✓ workspace/workflow/README.md - Workflow documentation

🚀 **Ready for Implementation**

The orchestrator prompt has been displayed above. As Claude Code, you should now:

1. 📖 Analyze the PRP file thoroughly
2. 🧠 ULTRATHINK the implementation approach  
3. 📋 Create workspace/workflow/tasks.md from the template
4. 🤖 Deploy first agent: .claude/scripts/execute/deploy-agent.sh 1

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# Main execution function
main() {
    local prp_path="$1"

    # Check if PRP path is provided
    if [[ -z "$prp_path" ]]; then
        echo "ERROR: No PRP file specified"
        usage
    fi
    local prp_path_abs
    prp_path_abs=$(realpath "$prp_path")
    if [[ ! -f "$prp_path_abs" ]]; then
        echo "ERROR: PRP file not found at '$1' (resolved to '$prp_path_abs')"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root: $PROJECT_ROOT"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PRP EXECUTION WORKFLOW INITIALIZATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 PRP File: $prp_path_abs"
    echo "📅 Started: $(date)"
    
    # Validate phase scripts exist
    validate_phase_scripts
    
    # Create master execution log
    create_master_log "$prp_path_abs"
    
    # Phase 1: PRP Validation
    run_phase ".claude/scripts/execute/validate-prp.sh" "Phase 1: PRP Validation" "$prp_path_abs"
    log_phase_completion "PRP Validation"
    
    # Export PRP_PATH for subsequent phases
    export PRP_PATH="$prp_path_abs"
    
    # Phase 2: workspace Setup  
    run_phase ".claude/scripts/execute/setup-workspace.sh" "Phase 2: workspace Setup"
    log_phase_completion "workspace Setup"
    
    # Source environment created by workspace setup
    if [[ -f "$PROJECT_ROOT/workspace/workflow/temp_env.sh" ]]; then
        source "$PROJECT_ROOT/workspace/workflow/temp_env.sh"
        echo "✓ Environment variables loaded from workspace setup"
    fi
    
    # Phase 3: Workflow Initialization
    run_phase ".claude/scripts/execute/initialize-workflow.sh" "Phase 3: Workflow Initialization"
    log_phase_completion "Workflow Initialization"
    
    # Phase 4: Orchestration
    run_phase ".claude/scripts/execute/orchestrate-execution.sh" "Phase 4: Orchestration"
    log_phase_completion "Orchestration"
    
    # Finalize logs and display summary
    finalize_execution_log
    display_final_summary "$prp_path_abs"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi