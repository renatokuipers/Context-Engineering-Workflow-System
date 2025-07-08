#!/bin/bash

# update-dependencies.sh - Update workflow dependencies tracking
# This script updates workflow/dependencies.md with component exports and dependencies

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script updates dependencies tracking using environment variables set by validation phase"
    exit 1
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "AGENT_NUM"
        "PROJECT_TYPE"
        "LANGUAGE"
        "WORKSPACE_PATH"
        "FILE_EXTENSIONS"
        "DEPENDENCIES_FILE"
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
    
    echo "✓ Environment variables validated for dependencies update"
}

# Function to extract exports from agent output (placeholder for now)
extract_agent_exports() {
    echo "📦 Extracting component exports from Agent $AGENT_NUM output..."
    
    # This is a placeholder for the actual export extraction
    # In a real implementation, this would parse the agent's output for:
    # - Class definitions with __init__ signatures
    # - Function definitions with signatures
    # - Constants and variables
    # - New package dependencies
    
    cat << EOF
[AGENT EXPORTS PLACEHOLDER]

Please replace this placeholder with the actual exports from Agent $AGENT_NUM's output.

Extract and document:
- **Classes**: All class definitions with their __init__ signatures and public methods
- **Functions**: All function definitions with their parameter and return types
- **Constants**: All module-level constants and their values
- **Dependencies**: Any new packages added to $DEPENDENCIES_FILE

Example format:
\`\`\`${LANGUAGE}
# From ${WORKSPACE_PATH}/module_name${FILE_EXTENSIONS}
class UserModel:
    def __init__(self, name: str, email: str): ...
    def validate(self) -> bool: ...
    def save(self) -> None: ...

def create_user(data: dict) -> UserModel: ...
def validate_email(email: str) -> bool: ...

DATABASE_URL: str = "sqlite:///app.db"
MAX_RETRIES: int = 3
\`\`\`
EOF
}

# Function to add agent exports to dependencies.md
add_agent_exports() {
    local agent_num="$1"
    
    echo "📝 Adding Agent $agent_num exports to dependencies.md..."
    
    local agent_exports=$(extract_agent_exports)
    
    # Find the "## Component Dependencies" or "## Exported Components" section
    local temp_file=$(mktemp)
    local section_found=false
    local exports_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Look for the exported components section
        if [[ "$line" == "## Exported Components" ]] || [[ "$line" == "## Component Dependencies" ]]; then
            section_found=true
        elif [[ "$section_found" == true ]] && [[ "$line" =~ ^\[.*\]$ ]] && [[ "$exports_added" == false ]]; then
            # This is a placeholder line, replace it
            echo "" >> "$temp_file"
            echo "## Agent $agent_num Exports" >> "$temp_file"
            echo "**Completed**: $(date)" >> "$temp_file"
            echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$agent_exports" >> "$temp_file"
            echo "" >> "$temp_file"
            exports_added=true
        elif [[ "$section_found" == true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ "$exports_added" == false ]]; then
            # We've hit the next section without finding a placeholder, add before this section
            echo "" >> "$temp_file"
            echo "## Agent $agent_num Exports" >> "$temp_file"
            echo "**Completed**: $(date)" >> "$temp_file"
            echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$agent_exports" >> "$temp_file"
            echo "" >> "$temp_file"
            exports_added=true
        fi
    done < workspace/workflow/dependencies.md
    
    # If we didn't add exports yet, add them at the end
    if [[ "$exports_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "## Agent $agent_num Exports" >> "$temp_file"
        echo "**Completed**: $(date)" >> "$temp_file"
        echo "**Workspace**: $WORKSPACE_PATH" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "$agent_exports" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/dependencies.md
    
    echo "✓ Agent exports added to dependencies.md"
}

# Function to update dependency tree visualization
update_dependency_tree() {
    local agent_num="$1"
    
    echo "🌳 Updating dependency tree..."
    
    # Create a simple dependency tree representation
    local temp_file=$(mktemp)
    local in_tree_section=false
    local tree_updated=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        if [[ "$line" == "## Dependency Tree" ]]; then
            in_tree_section=true
        elif [[ "$in_tree_section" == true ]] && [[ "$line" =~ ^\`\`\` ]] && [[ "$tree_updated" == false ]]; then
            # Found the start of the tree code block
            echo "$line" >> "$temp_file"
            
            # Add dependency tree entries based on completed agents
            for ((i=1; i<=agent_num; i++)); do
                local task_title=$(sed -n "/^## Task $i:/p" workspace/workflow/tasks.md | sed "s/## Task $i: //" | head -1)
                if [[ -n "$task_title" ]]; then
                    if [[ $i -eq 1 ]]; then
                        echo "Task $i: $task_title (foundational)" >> "$temp_file"
                    else
                        echo "Task $i: $task_title" >> "$temp_file"
                        echo "  ├── Depends on: Task $((i-1))" >> "$temp_file"
                    fi
                fi
            done
            
            tree_updated=true
            
            # Skip to the end of the existing tree block
            while IFS= read -r tree_line && [[ ! "$tree_line" =~ ^\`\`\`$ ]]; do
                # Skip existing tree content
                continue
            done
            echo "$tree_line" >> "$temp_file"  # Add the closing ```
        fi
    done < workspace/workflow/dependencies.md
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/dependencies.md
    
    echo "✓ Dependency tree updated"
}

# Function to check for new package dependencies
check_package_dependencies() {
    local agent_num="$1"
    
    echo "📦 Checking for new package dependencies..."
    
    # Check if the dependencies file has been updated
    local deps_file_path="workspace/$DEPENDENCIES_FILE"
    
    if [[ -f "$deps_file_path" ]]; then
        # Get modification time
        local mod_time=$(stat -c %Y "$deps_file_path" 2>/dev/null || stat -f %m "$deps_file_path" 2>/dev/null)
        local current_time=$(date +%s)
        local time_diff=$((current_time - mod_time))
        
        # If modified in the last hour (3600 seconds), it's likely from this agent
        if [[ $time_diff -lt 3600 ]]; then
            echo "📦 Dependencies file recently updated: $deps_file_path"
            
            # Add note to dependencies.md
            local temp_file=$(mktemp)
            local deps_section_found=false
            
            while IFS= read -r line; do
                echo "$line" >> "$temp_file"
                
                if [[ "$line" == "## Agent $agent_num Exports" ]]; then
                    deps_section_found=true
                elif [[ "$deps_section_found" == true ]] && [[ "$line" =~ ^##[[:space:]] ]]; then
                    # Add dependency update note before the next section
                    echo "**Package Dependencies**: Updated $DEPENDENCIES_FILE" >> "$temp_file"
                    echo "" >> "$temp_file"
                    deps_section_found=false
                fi
            done < workspace/workflow/dependencies.md
            
            mv "$temp_file" workspace/workflow/dependencies.md
        fi
    fi
    
    echo "✓ Package dependencies checked"
}

# Function to validate the dependencies update
validate_dependencies_update() {
    local agent_num="$1"
    
    echo "✅ Validating dependencies update..."
    
    # Check that the agent exports were added
    if ! grep -q "## Agent $agent_num Exports" workspace/workflow/dependencies.md; then
        echo "WARNING: Agent $agent_num exports may not have been properly added"
    fi
    
    # Check that the file is still readable
    if [[ ! -r workspace/workflow/dependencies.md ]]; then
        echo "ERROR: Dependencies file is no longer readable"
        exit 1
    fi
    
    echo "✓ Dependencies update validated"
}

# Function to log dependencies update
log_dependencies_update() {
    local agent_num="$1"
    
    {
        echo "[$(date)] Dependencies updated for Agent $agent_num"
        echo "[$(date)] Component exports documented"
        echo "[$(date)] Dependency tree updated"
    } >> workspace/workflow/execution.log
    
    echo "✓ Dependencies update logged"
}

# Function to create backup of dependencies before update
create_dependencies_backup() {
    local agent_num="$1"
    local backup_dir="workspace/workflow/backups"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    echo "💾 Creating dependencies backup..."
    
    mkdir -p "$backup_dir"
    
    if [[ -f workspace/workflow/dependencies.md ]]; then
        cp workspace/workflow/dependencies.md "${backup_dir}/dependencies.md.backup_agent${agent_num}_${timestamp}"
        echo "✓ Dependencies backup created"
    fi
}

# Main dependencies update function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "DEPENDENCIES UPDATE PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate environment
    validate_environment
    
    echo "📦 Processing dependencies for Agent $AGENT_NUM..."
    echo "🔧 Project Type: $PROJECT_TYPE"
    echo "💻 Language: $LANGUAGE"
    echo "📁 Workspace: $WORKSPACE_PATH"
    
    # Create backup
    create_dependencies_backup "$AGENT_NUM"
    
    # Update dependencies tracking
    add_agent_exports "$AGENT_NUM"
    update_dependency_tree "$AGENT_NUM"
    check_package_dependencies "$AGENT_NUM"
    
    # Validate the update
    validate_dependencies_update "$AGENT_NUM"
    
    # Log the update
    log_dependencies_update "$AGENT_NUM"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "DEPENDENCIES UPDATE COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi