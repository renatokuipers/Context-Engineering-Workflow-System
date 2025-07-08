#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
TASK_NUM=$1

cd "$PROJECT_ROOT"
echo "✅ Changed working directory to project root: $PROJECT_ROOT"

# Validate task number format
if [[ -z "$TASK_NUM" ]]; then
    echo "ERROR: No task number provided"
    echo "Usage: .claude/scripts/execute/deploy-agent.sh <task_number>"
    exit 1
fi

if [[ ! "$TASK_NUM" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Task number must be a positive integer"
    echo "Provided: $TASK_NUM"
    exit 1
fi

# Validate required files exist.
if [[ ! -f "workspace/workflow/tasks.md" ]]; then
    echo "ERROR: Tasks file not found: workspace/workflow/tasks.md"
    echo "Run the initiate-execution.sh script first to create the workflow structure."
    exit 1
fi

# Extract task title from tasks.md (just the title, not details)
TASK_TITLE=$(sed -n "/^## Task $TASK_NUM:/p" workspace/workflow/tasks.md | sed "s/## Task $TASK_NUM: //")

if [[ -z "$TASK_TITLE" ]]; then
    echo "ERROR: Task $TASK_NUM not found in workspace/workflow/tasks.md"
    echo "Available tasks:"
    grep "^## Task [0-9]\+:" workspace/workflow/tasks.md || echo "  No tasks found"
    exit 1
fi

# Check if task is already completed
if grep -q "Task $TASK_NUM: COMPLETE" workspace/workflow/progress.md 2>/dev/null; then
    echo "WARNING: Task $TASK_NUM appears to be already completed"
    echo "Task: $TASK_TITLE"
    echo "Continue anyway or continue with the next task?"
fi

# Check if previous task is completed (if not task 1)
if [[ "$TASK_NUM" -gt 1 ]]; then
    PREV_TASK=$((TASK_NUM - 1))
    if ! grep -q "Task $PREV_TASK: COMPLETE" workspace/workflow/progress.md 2>/dev/null; then
        echo "WARNING: Previous task (Task $PREV_TASK) may not be completed"
        echo "This could cause dependency issues."
        echo "Continue anyway or complete Task $PREV_TASK first?"
    fi
fi

# Export for instructions.sh to use later
export TASK_NUM

# Log the deployment
echo "[$(date)] Deploying Sub-Agent $TASK_NUM: $TASK_TITLE" >> workspace/workflow/execution.log

# Enhanced prompt for Claude Code to deploy the sub-agent
# The relative paths in this prompt are guaranteed to be correct because
# the orchestrator's context is rooted in the project directory.
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPLOY SUB-AGENT $TASK_NUM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Task Assignment
**Task $TASK_NUM**: $TASK_TITLE

## Instructions
1. Deploy a Sub-Agent using your TASK tool
2. The sub-agent should run ".claude/scripts/execute/instructions.sh" to receive detailed instructions
3. The sub-agent will implement the assigned component
4. After completion, run ".claude/scripts/execute/update-state.sh $TASK_NUM" to update progress

## Task Context
- Agent Number: $TASK_NUM
- Task Title: $TASK_TITLE
- Instruction Script: .claude/scripts/execute/instructions.sh

Deploy the sub-agent now.
EOF