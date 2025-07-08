#!/bin/bash

# instructions.sh - Provides a sub-agent with its complete, context-aware mission.
# This script is designed to be location-independent by calculating its own root directory.

# Finds the directory where THIS script lives, no matter where it's called from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assumes the script is in .claude/scripts/execute, so we go up three levels to find the project root.
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Load environment variable from deploy-agent.sh
TASK_NUM=${TASK_NUM:-1}

# This ensures we can always find our environment config.
ENV_FILE="$PROJECT_ROOT/workspace/workflow/environment.sh"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Validate task number
if [[ ! "$TASK_NUM" =~ ^[0-9]+$ ]] || [[ "$TASK_NUM" -lt 1 ]]; then
    echo "ERROR: Invalid task number: $TASK_NUM"
    exit 1
fi

# Define absolute paths to all required workflow files
DEPENDENCIES_MD_PATH="$PROJECT_ROOT/workspace/workflow/dependencies.md"
PROGRESS_MD_PATH="$PROJECT_ROOT/workspace/workflow/progress.md"
TASKS_MD_PATH="$PROJECT_ROOT/workspace/workflow/tasks.md"

# Validate required files exist using their absolute paths
if [[ ! -f "$DEPENDENCIES_MD_PATH" ]]; then
    echo "ERROR: Dependencies file not found: $DEPENDENCIES_MD_PATH"
    exit 1
fi

if [[ ! -f "$PROGRESS_MD_PATH" ]]; then
    echo "ERROR: Progress file not found: $PROGRESS_MD_PATH"
    exit 1
fi

if [[ ! -f "$TASKS_MD_PATH" ]]; then
    echo "ERROR: Tasks file not found: $TASKS_MD_PATH"
    exit 1
fi

# Load current state files using absolute paths
DEPENDENCIES=$(cat "$DEPENDENCIES_MD_PATH")
PROGRESS=$(cat "$PROGRESS_MD_PATH")
# PRP_PATH should already be absolute from the environment file
PROJECT_PRP=$(cat "$PRP_PATH" 2>/dev/null || echo "PRP file not available")

# Use dynamic workspace path from environment file (which should be absolute or reliably relative)
WORKSPACE="$WORKSPACE_PATH"

# Extract specific task details from tasks.md using absolute path
TASK_DETAILS=$(sed -n "/^## Task $TASK_NUM:/,/^## Task [0-9]\+:/p" "$TASKS_MD_PATH" | sed '1d;$d')

# Extract completed components from previous agents using absolute path
COMPLETED_COMPONENTS=""
for i in $(seq 1 $((TASK_NUM-1))); do
    AGENT_SECTION=$(sed -n "/^### Agent $i Output/,/^###/p" "$PROGRESS_MD_PATH" | sed '$d')
    if [ -n "$AGENT_SECTION" ]; then
        COMPLETED_COMPONENTS="${COMPLETED_COMPONENTS}${AGENT_SECTION}\n\n"
    fi
done

# Extract available imports from dependencies.md using absolute path
AVAILABLE_IMPORTS=""
for i in $(seq 1 $((TASK_NUM-1))); do
    IMPORTS=$(sed -n "/^## Agent $i Exports/,/^##[^#]/p" "$DEPENDENCIES_MD_PATH" | sed '1d;$d')
    if [ -n "$IMPORTS" ]; then
        AVAILABLE_IMPORTS="${AVAILABLE_IMPORTS}From Agent $i:\n${IMPORTS}\n\n"
    fi
done

# Output comprehensive instructions for the sub-agent
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUB-AGENT $TASK_NUM INSTRUCTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Root Directory
Your project root is: $PROJECT_ROOT

## Working Directory
You may ONLY create files in: $WORKSPACE_PATH
Tests must go in: $TEST_PATH

## Project Configuration
- **Project Type**: $PROJECT_TYPE
- **Language**: $LANGUAGE
- **File Extensions**: $FILE_EXTENSIONS
- **Build Command**: $BUILD_COMMAND
- **Test Command**: $TYPE_CHECK_COMMAND
- **Dependencies File**: $DEPENDENCIES_FILE

## Your Specific Task
$TASK_DETAILS

## Project Specifications
$PROJECT_PRP

## Your workspace
$WORKSPACE_PATH

## Available Imports from Previous Agents
$(if [ -n "$AVAILABLE_IMPORTS" ]; then
    echo -e "$AVAILABLE_IMPORTS"
else
    echo "None - you are the first agent"
fi)

## Previously Completed Components
$(if [ -n "$COMPLETED_COMPONENTS" ]; then
    echo -e "$COMPLETED_COMPONENTS"
else
    echo "None - you are the first agent"
fi)

## Current Project Dependencies
$DEPENDENCIES

## Implementation Requirements

1.  **ULTRATHINK** about your approach before starting.
2.  **Create a TODO list** using TodoWrite. Your plan MUST include a self-validation step.
    *   **Example TODO List:**
        - TODO 1: Implement the GameDetector class in $WORKSPACE_PATH/src/engine/game_detector.py
        - TODO 2: Add platform-specific logic for Windows (pywin32) and Linux (python-xlib).
        - TODO 3: Create unit tests in $TEST_PATH/unit/test_game_detector.py to cover both platforms and edge cases.
        - TODO 4: Run self-validation check: \`bash $PROJECT_ROOT/.claude/scripts/execute/check-file-size.sh $WORKSPACE_PATH/src/engine/game_detector.py\`
        - TODO 5: If validation passes, create my final summary.

3.  **Implement** with these constraints:
    - **100% functional code** - ZERO placeholders, TODOs, or stubs.
    - **LEAN code** - Maximum 500 lines per file. This is a strict, non-negotiable rule.
    - **Language-appropriate standards** - Follow $LANGUAGE best practices.
    - **Tests** for core functionality in $TEST_PATH.
    - **Cross-platform** compatibility where applicable.

4.  **Language-specific guidance**:
    $FRAMEWORK_HINTS

5.  **Performance considerations**:
    $PERFORMANCE_HINTS

6.  **Code organization**:
    - Clear module separation
    - Descriptive file names
    - Proper error handling
    - Documentation for public APIs

## Self-Validation & Finalization

1.  **Run Compliance Check**: After implementing your code and tests, you MUST run the file size compliance check on ALL new source files you created.
    - **Command**: \`bash $PROJECT_ROOT/.claude/scripts/execute/check-file-size.sh [path/to/your/file1.py] [path/to/your/file2.py] ...\`
    
2.  **Analyze the Result**:
    - **If it passes**: The script will output "✅ SUCCESS". You can proceed to the next step.
    - **If it fails**: The script will HALT and give you a new set of instructions to refactor your oversized code. You MUST follow these new instructions, refactor your code, re-run tests, and then run the check script again until it passes.
    
3.  **Create Final Summary**: ONLY after the \`check-file-size.sh\` script passes, provide your summary with the following sections:

### Summary
[Brief description of what you implemented]

### Created Files
- $WORKSPACE_PATH/path/to/file$FILE_EXTENSIONS
- $TEST_PATH/test_something$FILE_EXTENSIONS

### Exported Components
\`\`\`$LANGUAGE
# From $WORKSPACE_PATH/module/file$FILE_EXTENSIONS
class ClassName:
    def __init__(self, param1: type, param2: type): ...
    def public_method(self) -> return_type: ...

def function_name(arg: type) -> return_type: ...

CONSTANT_NAME: type = value
\`\`\`

### New Dependencies
[Any new packages added to $DEPENDENCIES_FILE]

### Integration Notes
[Any important notes for agents implementing dependent components]

### Cleanup Completed
[Confirm all temporary files removed]

When you are done, Show this exact messsage: "I have finished my task, please run '$PROJECT_ROOT/.claude/scripts/execute/update-state.sh'"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BEGIN IMPLEMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF