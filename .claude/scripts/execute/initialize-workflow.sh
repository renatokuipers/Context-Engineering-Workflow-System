#!/bin/bash

# initialize-workflow.sh - Create workflow tracking files
# This script creates and initializes all workflow tracking files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script initializes workflow tracking files using environment variables set by previous phases"
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
        echo "Please run the previous phases (validate-prp.sh and setup-workspace.sh) first."
        exit 1
    fi
    
    echo "✓ Environment variables validated"
}

# Function to create progress tracking file
create_progress_file() {
    local progress_file="$PROJECT_ROOT/workspace/workflow/progress.md"
    
    echo "📊 Creating progress tracking file: $progress_file"
    
    cat > "$progress_file" << EOF
# Execution Progress for ${PRP_PATH}

**Started**: $(date)  
**Project Type**: ${PROJECT_TYPE}  
**Language**: ${LANGUAGE}  
**workspace**: ${WORKSPACE_PATH}  
**Test Directory**: ${TEST_PATH}

## Project Configuration
- **Dependencies File**: ${DEPENDENCIES_FILE}
- **Build Command**: ${BUILD_COMMAND}
- **Test Command**: ${TYPE_CHECK_COMMAND}
- **File Extensions**: ${FILE_EXTENSIONS}

## Agent Status
[Pending task extraction]

## Task Progress
[To be updated as tasks are created and completed]

## Completed Components
[None yet]

## Issues and Blockers
[None currently]

## Timeline
- **$(date)**: Workflow initialized
EOF
    
    if [[ -f "$progress_file" ]]; then
        echo "✓ Progress file created successfully"
    else
        echo "ERROR: Failed to create progress file"
        exit 1
    fi
}

# Function to create dependencies tracking file
create_dependencies_file() {
    local deps_file="$PROJECT_ROOT/workspace/workflow/dependencies.md"
    
    echo "🔗 Creating dependencies tracking file: $deps_file"
    
    cat > "$deps_file" << EOF
# Dependency Graph

**Generated**: $(date)  
**Project Type**: ${PROJECT_TYPE}  
**Language**: ${LANGUAGE}

## Core Dependencies
- **Language**: ${LANGUAGE}
- **Dependencies File**: ${DEPENDENCIES_FILE}
- **Build Command**: ${BUILD_COMMAND}
- **Test Command**: ${TYPE_CHECK_COMMAND}
- **Lint Command**: ${LINT_COMMAND:-"Not specified"}
- **Install Command**: ${INSTALL_COMMAND:-"Not specified"}

## Framework Guidelines
${FRAMEWORK_HINTS:-"Generic development practices"}

## Performance Considerations
${PERFORMANCE_HINTS:-"Standard performance practices"}

## Component Dependencies
[To be mapped during execution as agents complete their tasks]

## Exported Components
[To be populated by agents as they complete implementation]

## Integration Points
[To be documented as components are integrated]

## Dependency Tree
\`\`\`
[Visual dependency tree will be built as components are added]
\`\`\`

## Known Issues
[Any dependency conflicts or issues will be documented here]
EOF
    
    if [[ -f "$deps_file" ]]; then
        echo "✓ Dependencies file created successfully"
    else
        echo "ERROR: Failed to create dependencies file"
        exit 1
    fi
}

# Function to create execution log file
create_execution_log() {
    local log_file="$PROJECT_ROOT/workspace/workflow/execution.log"
    
    echo "📝 Creating execution log file: $log_file"
    
    {
        echo "[$(date)] =========================================="
        echo "[$(date)] WORKFLOW INITIALIZATION STARTED"
        echo "[$(date)] =========================================="
        echo "[$(date)] PRP File: ${PRP_PATH}"
        echo "[$(date)] Project Type: ${PROJECT_TYPE}"
        echo "[$(date)] Language: ${LANGUAGE}"
        echo "[$(date)] workspace: ${WORKSPACE_PATH}"
        echo "[$(date)] Test Directory: ${TEST_PATH}"
        echo "[$(date)] Dependencies File: ${DEPENDENCIES_FILE}"
        echo "[$(date)] Build Command: ${BUILD_COMMAND}"
        echo "[$(date)] =========================================="
        echo "[$(date)] WORKFLOW INITIALIZATION COMPLETED"
        echo "[$(date)] =========================================="
    } > "$log_file"
    
    if [[ -f "$log_file" ]]; then
        echo "✓ Execution log created successfully"
    else
        echo "ERROR: Failed to create execution log"
        exit 1
    fi
}

# Function to create tasks template file
create_tasks_template() {
    local tasks_file="$PROJECT_ROOT/workspace/workflow/tasks.template.md"
    
    echo "📋 Creating tasks template file: $tasks_file"
    
    cat > "$tasks_file" << EOF
# Implementation Tasks Template

Use this template to create workspace/workflow/tasks.md with your specific implementation tasks.

## Task Format
Each task should follow this structure:

\`\`\`markdown
## Task N: [Component Name]
- **Description**: What this component does and its purpose
- **Key Classes/Modules**: List of main classes, functions, or modules to implement
- **Files to Create**: Specific file paths in ${WORKSPACE_PATH}
- **Test Files**: Corresponding test files in ${TEST_PATH}
- **Dependencies**: Which previous tasks this depends on (or "None" for first task)
- **Exports**: What this task will export for other tasks to use
- **Estimated Complexity**: Simple/Medium/Complex
\`\`\`

## Example Task

\`\`\`markdown
## Task 1: Core Data Models
- **Description**: Implement the fundamental data structures and models for the application
- **Key Classes/Modules**: User, Project, Task, Configuration classes
- **Files to Create**: 
  - ${WORKSPACE_PATH}/models/user${FILE_EXTENSIONS}
  - ${WORKSPACE_PATH}/models/project${FILE_EXTENSIONS}
  - ${WORKSPACE_PATH}/models/task${FILE_EXTENSIONS}
- **Test Files**: 
  - ${TEST_PATH}/test_models${FILE_EXTENSIONS}
- **Dependencies**: None (foundational component)
- **Exports**: User, Project, Task, Configuration classes
- **Estimated Complexity**: Medium
\`\`\`

## Guidelines for Task Creation

1. **Order by Dependencies**: List foundational components first
2. **Single Responsibility**: Each task should focus on one logical component
3. **Clear Boundaries**: Avoid overlap between tasks
4. **Testable Units**: Each task should produce testable components
5. **File Size Limit**: Ensure no single file exceeds 500 lines
6. **Integration Points**: Clearly specify what each task exports

## Next Steps

1. Analyze your PRP requirements
2. Copy this template to workspace/workflow/tasks.md
3. Replace the example with your actual tasks
4. Ensure proper dependency ordering
5. Begin execution with: \`.claude/scripts/execute/deploy-agent.sh 1\`
EOF
    
    if [[ -f "$tasks_file" ]]; then
        echo "✓ Tasks template created successfully"
    else
        echo "ERROR: Failed to create tasks template"
        exit 1
    fi
}

# Function to create environment variables file
create_environment_file() {
    local env_file="$PROJECT_ROOT/workspace/workflow/environment.sh"
    
    echo "🔧 Creating environment variables file: $env_file"
    
    cat > "$env_file" << EOF
#!/bin/bash
# Environment variables for workflow execution
# This file is sourced by other scripts to ensure consistent environment

# Project Configuration
export PROJECT_TYPE="${PROJECT_TYPE}"
export LANGUAGE="${LANGUAGE}"
export FILE_EXTENSIONS="${FILE_EXTENSIONS}"

# Paths
export PRP_PATH="${PRP_PATH}"
export WORKSPACE_PATH="${WORKSPACE_PATH}"
export TEST_PATH="${TEST_PATH}"
export PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)/workspace}"
export WORKFLOW_DIR="${WORKFLOW_DIR:-$(pwd)/workspace/workflow}"

# Commands
export BUILD_COMMAND="${BUILD_COMMAND}"
export LINT_COMMAND="${LINT_COMMAND}"
export TYPE_CHECK_COMMAND="${TYPE_CHECK_COMMAND}"
export INSTALL_COMMAND="${INSTALL_COMMAND}"
export RUN_COMMAND="${RUN_COMMAND}"

# Files
export DEPENDENCIES_FILE="${DEPENDENCIES_FILE}"
export PROGRESS_FILE="${WORKFLOW_DIR}/progress.md"
export DEPENDENCIES_MD="${WORKFLOW_DIR}/dependencies.md"
export TASKS_FILE="${WORKFLOW_DIR}/tasks.md"
export EXECUTION_LOG="${WORKFLOW_DIR}/execution.log"

# Guidelines
export FRAMEWORK_HINTS="${FRAMEWORK_HINTS}"
export PERFORMANCE_HINTS="${PERFORMANCE_HINTS}"

# Workflow State
export WORKFLOW_INITIALIZED="true"
export WORKFLOW_INIT_TIME="$(date)"

echo "Environment variables loaded for ${PROJECT_TYPE} project"
EOF
    
    chmod +x "$env_file"
    
    if [[ -f "$env_file" ]]; then
        echo "✓ Environment file created successfully"
    else
        echo "ERROR: Failed to create environment file"
        exit 1
    fi
}

# Function to create workflow summary
create_workflow_summary() {
    local summary_file="$PROJECT_ROOT/workspace/workflow/README.md"
    
    echo "📖 Creating workflow summary: $summary_file"
    
    cat > "$summary_file" << EOF
# Workflow Summary

This directory contains all workflow tracking and management files for the PRP execution.

## Files

### Core Tracking Files
- **progress.md**: Overall execution progress and completed components
- **dependencies.md**: Component dependencies and exported interfaces  
- **tasks.md**: Detailed task breakdown (create this from tasks.template.md)
- **execution.log**: Detailed execution log with timestamps

### Templates and Configuration
- **tasks.template.md**: Template for creating tasks.md
- **environment.sh**: Environment variables for consistent execution
- **README.md**: This summary file

### Generated Files
- **validation.log**: PRP validation results
- **setup.log**: workspace setup results

## Project Configuration

- **Type**: ${PROJECT_TYPE}
- **Language**: ${LANGUAGE}
- **workspace**: ${WORKSPACE_PATH}
- **Tests**: ${TEST_PATH}

## Usage

1. **Initial Setup**: Run \`.claude/scripts/execute/initiate-execution.sh <prp_file>\`
2. **Create Tasks**: Copy tasks.template.md to tasks.md and customize
3. **Execute**: Run \`.claude/scripts/execute/deploy-agent.sh 1\` to start first agent
4. **Monitor**: Check progress.md for status updates
5. **Continue**: After each agent, run \`.claude/scripts/execute/update-state.sh N\`

## Workflow Status

- **Initialized**: $(date)
- **PRP File**: ${PRP_PATH}
- **Ready for Task Creation**: ✓

## Next Steps

Create workspace/workflow/tasks.md from the template and begin agent deployment.
EOF
    
    if [[ -f "$summary_file" ]]; then
        echo "✓ Workflow summary created successfully"
    else
        echo "ERROR: Failed to create workflow summary"
        exit 1
    fi
}

# Function to validate all created files
validate_workflow_files() {
    echo "✅ Validating workflow files..."
    
    local required_files=(
        "$PROJECT_ROOT/workspace/workflow/progress.md"
        "$PROJECT_ROOT/workspace/workflow/dependencies.md"
        "$PROJECT_ROOT/workspace/workflow/execution.log"
        "$PROJECT_ROOT/workspace/workflow/tasks.template.md"
        "$PROJECT_ROOT/workspace/workflow/environment.sh"
        "$PROJECT_ROOT/workspace/workflow/README.md"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "ERROR: Missing workflow files:"
        printf "  - %s\n" "${missing_files[@]}"
        exit 1
    fi
    
    echo "✓ All workflow files validated successfully"
}

# Function to log initialization completion
log_initialization() {
    local log_file="$PROJECT_ROOT/workspace/workflow/initialization.log"
    
    {
        echo "[$(date)] Workflow Initialization Completed"
        echo "PRP File: ${PRP_PATH}"
        echo "Project Type: ${PROJECT_TYPE}"
        echo "Language: ${LANGUAGE}"
        echo "workspace: ${WORKSPACE_PATH}"
        echo "Files Created:"
        echo "  - workspace/workflow/progress.md"
        echo "  - workspace/workflow/dependencies.md"
        echo "  - workspace/workflow/execution.log"
        echo "  - workspace/workflow/tasks.template.md"
        echo "  - workspace/workflow/environment.sh"
        echo "  - workspace/workflow/README.md"
        echo "Status: SUCCESS"
        echo "Next Step: Create workspace/workflow/tasks.md from template"
        echo "---"
    } >> "$log_file"
    
    echo "✓ Initialization logged to: $log_file"
}

# Main initialization function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "WORKFLOW INITIALIZATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root: $PROJECT_ROOT"

    # Validate environment variables
    validate_environment
    
    # Create all workflow files
    create_progress_file
    create_dependencies_file
    create_execution_log
    create_tasks_template
    create_environment_file
    create_workflow_summary
    
    # Validate all files were created
    validate_workflow_files
    
    # Log completion
    log_initialization
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "WORKFLOW INITIALIZATION COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi