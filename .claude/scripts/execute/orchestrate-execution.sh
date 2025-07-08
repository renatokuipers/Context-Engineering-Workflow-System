#!/bin/bash

# orchestrate-execution.sh - Output orchestrator prompt for Claude Code
# This script generates the final orchestrator prompt for Claude Code to begin the implementation phase

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script generates the orchestrator prompt using environment variables set by previous phases"
    exit 1
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "PRP_PATH"
        "PROJECT_TYPE"
        "LANGUAGE"
        "WORKSPACE_PATH"
        "TEST_PATH"
        "DEPENDENCIES_FILE"
        "BUILD_COMMAND"
        "TYPE_CHECK_COMMAND"
        "FILE_EXTENSIONS"
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
        echo "Please run the previous phases first."
        exit 1
    fi
    
    echo "✓ Environment variables validated for orchestration"
}

# Function to check if workflow files exist
validate_workflow_files() {
    local required_files=(
        "workspace/workflow/progress.md"
        "workspace/workflow/dependencies.md"
        "workspace/workflow/execution.log"
        "workspace/workflow/tasks.template.md"
        "workspace/workflow/environment.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "ERROR: Missing workflow files:"
        printf "  - %s\n" "${missing_files[@]}"
        echo "Please run initialize-workflow.sh first."
        exit 1
    fi
    
    echo "✓ Workflow files validated"
}

# Function to log orchestration start
log_orchestration_start() {
    echo "[$(date)] Orchestration phase initiated" >> "$PROJECT_ROOT/workspace/workflow/execution.log"
    echo "[$(date)] Ready for task creation and agent deployment" >> "$PROJECT_ROOT/workspace/workflow/execution.log"
}

# Function to generate the orchestrator prompt
generate_orchestrator_prompt() {
    echo "🎭 Generating orchestrator prompt for Claude Code..."
    
    # This makes the commands copy-paste-able and robust.
    local deploy_script_path="$PROJECT_ROOT/.claude/scripts/execute/deploy-agent.sh"
    local update_script_path="$PROJECT_ROOT/.claude/scripts/execute/update-state.sh"
    
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRP EXECUTION ORCHESTRATOR ACTIVATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Your Role
You are the orchestrator for implementing this PRP using sequential sub-agents.
The automated workflow system is now active and fully initialized.

## Project Configuration
- **Project Type**: ${PROJECT_TYPE}
- **Language**: ${LANGUAGE}
- **workspace**: ${WORKSPACE_PATH}
- **Test Directory**: ${TEST_PATH}
- **Dependencies File**: ${DEPENDENCIES_FILE}
- **Build Command**: ${BUILD_COMMAND}
- **Test Command**: ${TYPE_CHECK_COMMAND}
- **File Extensions**: ${FILE_EXTENSIONS}

## Framework Guidelines
${FRAMEWORK_HINTS:-"Follow language-specific best practices"}

## Performance Considerations
${PERFORMANCE_HINTS:-"Standard performance optimization practices"}

## Phase 1: Analysis & Planning

### 1. Load and Analyze PRP
- Read the PRP file thoroughly: **${PRP_PATH}**
- Understand all requirements and context
- Identify major components/modules needed
- Consider the target ${LANGUAGE} implementation approach

### 2. ULTRATHINK about the implementation
- Identify logical component order based on dependencies
- Map out which components need to be built before others
- Consider integration points between components
- Plan for ${PROJECT_TYPE}-specific architecture patterns
- Think about testing strategy for ${TEST_PATH}

### 3. Create Task Breakdown
Create **$PROJECT_ROOT/workspace/workflow/tasks.md** with numbered tasks using this format:

\`\`\`markdown
# Implementation Tasks for [Project Name]

## Task 1: [Component Name]
- **Description**: What this component does and its purpose
- **Key Classes/Modules**: List of main classes, functions, or modules to implement
- **Files to Create**: 
  - ${WORKSPACE_PATH}/module_name${FILE_EXTENSIONS}
  - ${WORKSPACE_PATH}/utils/helper${FILE_EXTENSIONS}
- **Test Files**: 
  - ${TEST_PATH}/test_module${FILE_EXTENSIONS}
- **Dependencies**: None (foundational component)
- **Exports**: List of classes, functions, constants this task will export
- **Estimated Complexity**: Simple/Medium/Complex

## Task 2: [Component Name]
- **Description**: Description of second component
- **Key Classes/Modules**: Components to implement
- **Files to Create**: Specific ${LANGUAGE} files in ${WORKSPACE_PATH}
- **Test Files**: Corresponding tests in ${TEST_PATH}
- **Dependencies**: Task 1 exports (specify what you'll import)
- **Exports**: What this task provides to future tasks
- **Estimated Complexity**: Simple/Medium/Complex

[Continue for all components...]
\`\`\`

### Important Task Creation Guidelines:
- **Order by Dependencies**: Foundational components first, dependent ones later
- **File Size Limit**: No file should exceed 500 lines (split if needed)
- **Single Responsibility**: Each task focuses on one logical component
- **Clear Exports**: Specify exactly what each task provides to others
- **Test Coverage**: Every task must include corresponding tests
- **${LANGUAGE} Best Practices**: Follow ${LANGUAGE}-specific conventions

## Phase 2: Sequential Execution

After creating **$PROJECT_ROOT/workspace/workflow/tasks.md**, deploy sub-agents sequentially:

1. **Deploy first agent**: \`bash ${deploy_script_path} 1\`
2. **Wait for completion**: Agent implements Task 1 component
3. **Update state**: \`bash ${update_script_path} 1\`
4. **Review progress**: Check **$PROJECT_ROOT/workspace/workflow/progress.md** and **$PROJECT_ROOT/workspace/workflow/dependencies.md**
5. **Deploy next agent**: \`bash ${deploy_script_path} 2\`
6. **Repeat**: Continue until all tasks complete

### Agent Coordination Benefits:
- Each agent focuses on one component (better quality)
- Dependencies tracked automatically (no import errors)
- Progress visibility throughout implementation
- Easier debugging and testing per component
- Clean, organized ${LANGUAGE} codebase structure

## Phase 3: Final Validation

Once all agents complete:

### Build and Test Validation:
- Run build command: **${BUILD_COMMAND}**
- Run test suite: **${TYPE_CHECK_COMMAND}**
- Verify all components integrate properly
- Check ${DEPENDENCIES_FILE} is complete and accurate

### PRP Requirements Check:
- Ensure all PRP requirements are met
- Verify functionality matches specifications
- Test end-to-end workflows
- Validate ${LANGUAGE}-specific requirements

### Quality Assurance:
- All files under 500 lines ✓
- Proper ${LANGUAGE} code structure ✓
- Complete test coverage ✓
- Documentation for public APIs ✓

## Workflow Files Ready
- **Progress Tracking**: $PROJECT_ROOT/workspace/workflow/progress.md
- **Dependencies**: $PROJECT_ROOT/workspace/workflow/dependencies.md  
- **Execution Log**: $PROJECT_ROOT/workspace/workflow/execution.log
- **Task Template**: $PROJECT_ROOT/workspace/workflow/tasks.template.md (copy to tasks.md)
- **Environment**: $PROJECT_ROOT/workspace/workflow/environment.sh
- **Summary**: $PROJECT_ROOT/workspace/workflow/README.md

## Next Action
**Begin by analyzing the PRP file (${PRP_PATH}) and creating $PROJECT_ROOT/workspace/workflow/tasks.md with your ${PROJECT_TYPE} component breakdown.**

Remember: Each task = one focused component. Order by dependencies. Keep files under 500 lines.

EOF
}

# Function to display next steps
display_next_steps() {
    local deploy_script_path="$PROJECT_ROOT/.claude/scripts/execute/deploy-agent.sh"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "NEXT STEPS FOR CLAUDE CODE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. 📖 Analyze PRP file: ${PRP_PATH}"
    echo "2. 🧠 ULTRATHINK the ${PROJECT_TYPE} implementation approach"
    echo "3. 📋 Create $PROJECT_ROOT/workspace/workflow/tasks.md from $PROJECT_ROOT/workspace/workflow/tasks.template.md"
    echo "4. 🚀 Deploy first agent: bash ${deploy_script_path} 1"
    echo ""
    echo "Workflow initialized for ${PROJECT_TYPE} project in ${LANGUAGE}."
    echo "Ready for task creation and sequential agent deployment."
    echo ""
}

# Main orchestration function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ORCHESTRATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root: $PROJECT_ROOT"
    
    # Validate environment and files
    validate_environment
    validate_workflow_files
    
    # Log orchestration start
    log_orchestration_start
    
    # Generate the orchestrator prompt
    generate_orchestrator_prompt
    
    # Display next steps
    display_next_steps
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ORCHESTRATION COMPLETE - READY FOR TASK CREATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi