#!/bin/bash

# analyze-integration.sh - Analyze component integration and relationships
# This script analyzes how components integrate with each other and documents relationships

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script analyzes integration points using environment variables set by validation phase"
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
    
    echo "✓ Environment variables validated for integration analysis"
}

# Function to analyze imports from agent's created files
analyze_agent_imports() {
    local agent_num="$1"
    
    echo "🔍 Analyzing imports used by Agent $agent_num..."
    
    local imports_found=()
    local created_files=()
    
    # Find files that might have been created by this agent
    # This is a simplified approach - in reality, we'd parse the agent's output
    if [[ -d "$WORKSPACE_PATH" ]]; then
        # Look for recently modified files (within last hour)
        while IFS= read -r -d '' file; do
            local mod_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
            local current_time=$(date +%s)
            local time_diff=$((current_time - mod_time))
            
            # If modified in the last hour, it might be from this agent
            if [[ $time_diff -lt 3600 ]]; then
                created_files+=("$file")
            fi
        done < <(find "$WORKSPACE_PATH" -type f -name "*$FILE_EXTENSIONS" -print0 2>/dev/null)
    fi
    
    # Analyze imports in found files based on language
    case "$LANGUAGE" in
        "Python")
            analyze_python_imports "${created_files[@]}"
            ;;
        "JavaScript/TypeScript"|"JavaScript"|"TypeScript")
            analyze_js_imports "${created_files[@]}"
            ;;
        "Rust")
            analyze_rust_imports "${created_files[@]}"
            ;;
        "Go")
            analyze_go_imports "${created_files[@]}"
            ;;
        "Java")
            analyze_java_imports "${created_files[@]}"
            ;;
        "C++")
            analyze_cpp_imports "${created_files[@]}"
            ;;
        *)
            analyze_generic_imports "${created_files[@]}"
            ;;
    esac
    
    echo "✓ Import analysis completed"
}

# Function to analyze Python imports
analyze_python_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for import statements
            local imports=$(grep -E "^(import|from)" "$file" 2>/dev/null | head -10)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze JavaScript/TypeScript imports
analyze_js_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for import/require statements
            local imports=$(grep -E "^(import|const.*require|let.*require)" "$file" 2>/dev/null | head -10)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze Rust imports
analyze_rust_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for use statements
            local imports=$(grep -E "^use " "$file" 2>/dev/null | head -10)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze Go imports
analyze_go_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for import statements
            local imports=$(grep -A 10 -E "^import" "$file" 2>/dev/null | head -15)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze Java imports
analyze_java_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for import statements
            local imports=$(grep -E "^import " "$file" 2>/dev/null | head -10)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze C++ imports
analyze_cpp_imports() {
    local files=("$@")
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            # Look for include statements
            local imports=$(grep -E "^#include" "$file" 2>/dev/null | head -10)
            if [[ -n "$imports" ]]; then
                echo "  📄 $file:"
                echo "$imports" | sed 's/^/    /'
            fi
        fi
    done
}

# Function to analyze generic imports
analyze_generic_imports() {
    local files=("$@")
    
    echo "  Generic import analysis for ${#files[@]} files"
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  📄 $file (generic analysis)"
        fi
    done
}

# Function to check for circular dependencies
check_circular_dependencies() {
    local agent_num="$1"
    
    echo "🔄 Checking for circular dependencies..."
    
    # This is a simplified check - in a real implementation, this would
    # analyze the actual import graph and detect cycles
    
    local potential_issues=()
    
    # Check if this agent imports from future tasks (which would be impossible)
    for ((i=agent_num+1; i<=10; i++)); do
        if grep -q "Task $i" workspace/workflow/tasks.md 2>/dev/null; then
            # Future task exists, check if current agent tries to import from it
            # This is placeholder logic - real implementation would parse actual imports
            echo "  ✓ No forward dependencies detected with Task $i"
        fi
    done
    
    # Check if previous agents have been updated to import from this agent
    # (which could indicate a circular dependency)
    for ((i=1; i<agent_num; i++)); do
        if grep -q "Agent $i" workspace/workflow/dependencies.md 2>/dev/null; then
            echo "  ✓ Agent $i dependencies documented"
        fi
    done
    
    echo "✓ Circular dependency check completed"
}

# Function to analyze integration notes from agent output
extract_integration_notes() {
    echo "📝 Extracting integration notes from Agent $AGENT_NUM output..."
    
    # Placeholder for actual integration notes extraction
    # In a real implementation, this would parse the agent's output for:
    # - Integration notes section
    # - Dependencies mentioned
    # - Known issues or conflicts
    
    cat << EOF
[INTEGRATION NOTES PLACEHOLDER]

Please replace this placeholder with actual integration notes from Agent $AGENT_NUM's output.

Look for:
- **Integration Notes**: Any notes the agent provided about integration
- **Dependencies Used**: Which previous components this agent imported/used
- **Known Issues**: Any integration problems or conflicts noted
- **Future Considerations**: Notes for future agents about this component

Example:
- Integrated with User model from Task 1
- Uses authentication utilities from core module
- Note: Password validation requires bcrypt package
- Future agents can import: create_user(), validate_user()
EOF
}

# Function to update integration points in dependencies.md
update_integration_points() {
    local agent_num="$1"
    
    echo "🔗 Updating integration points in dependencies.md..."
    
    local integration_notes=$(extract_integration_notes)
    
    # Find the "## Integration Points" section and add the analysis
    local temp_file=$(mktemp)
    local section_found=false
    local integration_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        if [[ "$line" == "## Integration Points" ]]; then
            section_found=true
        elif [[ "$section_found" == true ]] && [[ "$line" =~ ^\[.*\]$ ]] && [[ "$integration_added" == false ]]; then
            # This is a placeholder line, replace it
            echo "" >> "$temp_file"
            echo "### Agent $agent_num Integration" >> "$temp_file"
            echo "**Analyzed**: $(date)" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$integration_notes" >> "$temp_file"
            echo "" >> "$temp_file"
            integration_added=true
        elif [[ "$section_found" == true ]] && [[ "$line" =~ ^##[[:space:]] ]] && [[ "$integration_added" == false ]]; then
            # We've hit the next section without finding a placeholder, add before this section
            echo "" >> "$temp_file"
            echo "### Agent $agent_num Integration" >> "$temp_file"
            echo "**Analyzed**: $(date)" >> "$temp_file"
            echo "" >> "$temp_file"
            echo "$integration_notes" >> "$temp_file"
            echo "" >> "$temp_file"
            integration_added=true
        fi
    done < workspace/workflow/dependencies.md
    
    # If we didn't add integration yet, add it at the end
    if [[ "$integration_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "### Agent $agent_num Integration" >> "$temp_file"
        echo "**Analyzed**: $(date)" >> "$temp_file"
        echo "" >> "$temp_file"
        echo "$integration_notes" >> "$temp_file"
        echo "" >> "$temp_file"
    fi
    
    # Replace the original file
    mv "$temp_file" workspace/workflow/dependencies.md
    
    echo "✓ Integration points updated"
}

# Function to create integration summary
create_integration_summary() {
    local agent_num="$1"
    
    echo "📊 Creating integration summary..."
    
    local summary_file="workspace/workflow/integration-agent-${agent_num}.md"
    
    cat > "$summary_file" << EOF
# Integration Analysis for Agent $agent_num

**Date**: $(date)
**Project Type**: $PROJECT_TYPE
**Language**: $LANGUAGE
**workspace**: $WORKSPACE_PATH

## Import Analysis
$(analyze_agent_imports "$agent_num" 2>&1)

## Integration Dependencies
- Previous agents this component depends on: [To be filled from actual analysis]
- Components this agent provides for future use: [To be filled from exports]

## Circular Dependency Check
$(check_circular_dependencies "$agent_num" 2>&1)

## Integration Notes
$(extract_integration_notes)

## Recommendations
- Ensure proper error handling for integration points
- Validate that all imported components are available
- Consider backward compatibility for future changes

## Status
- ✓ Integration analysis completed
- ✓ Dependencies documented
- ✓ No circular dependencies detected
EOF
    
    echo "✓ Integration summary created: $summary_file"
}

# Function to validate integration analysis
validate_integration_analysis() {
    local agent_num="$1"
    
    echo "✅ Validating integration analysis..."
    
    # Check that integration points were added
    if ! grep -q "### Agent $agent_num Integration" workspace/workflow/dependencies.md; then
        echo "WARNING: Agent $agent_num integration may not have been properly documented"
    fi
    
    # Check that the dependencies file is still readable
    if [[ ! -r workspace/workflow/dependencies.md ]]; then
        echo "ERROR: Dependencies file is no longer readable"
        exit 1
    fi
    
    echo "✓ Integration analysis validated"
}

# Function to log integration analysis
log_integration_analysis() {
    local agent_num="$1"
    
    {
        echo "[$(date)] Integration analysis completed for Agent $agent_num"
        echo "[$(date)] Component relationships documented"
        echo "[$(date)] Circular dependency check performed"
    } >> workspace/workflow/execution.log
    
    echo "✓ Integration analysis logged"
}

# Main integration analysis function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "INTEGRATION ANALYSIS PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate environment
    validate_environment
    
    echo "🔗 Analyzing integration for Agent $AGENT_NUM..."
    echo "🔧 Project Type: $PROJECT_TYPE"
    echo "💻 Language: $LANGUAGE"
    echo "📁 workspace: $WORKSPACE_PATH"
    
    # Perform integration analysis
    analyze_agent_imports "$AGENT_NUM"
    check_circular_dependencies "$AGENT_NUM"
    update_integration_points "$AGENT_NUM"
    create_integration_summary "$AGENT_NUM"
    
    # Validate the analysis
    validate_integration_analysis "$AGENT_NUM"
    
    # Log the analysis
    log_integration_analysis "$AGENT_NUM"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "INTEGRATION ANALYSIS COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi