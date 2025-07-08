#!/bin/bash

# validate-file-structure.sh - Validate file structure and compliance
# This script validates that files are created in correct locations and meet size/structure requirements

# Function to display usage
usage() {
    echo "Usage: $0"
    echo "This script validates file structure using environment variables set by validation phase"
    exit 1
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "AGENT_NUM"
        "PROJECT_TYPE"
        "LANGUAGE"
        "WORKSPACE_PATH"
        "TEST_PATH"
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
    
    echo "✓ Environment variables validated for file structure validation"
}

# Function to find files created by this agent
find_agent_files() {
    local agent_num="$1"
    
    echo "🔍 Finding files created by Agent $agent_num in '$WORKSPACE_PATH' and '$TEST_PATH'..."
    
    local created_files=()
    
    # Search only within the designated workspace and test paths.
    local search_paths=("$WORKSPACE_PATH" "$TEST_PATH")
    
    for path in "${search_paths[@]}"; do
        if [[ -d "$path" ]]; then
            # Find files modified in the last hour (3600 seconds), which are likely from this agent.
            while IFS= read -r -d '' file; do
                local mod_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
                local current_time=$(date +%s)
                local time_diff=$((current_time - mod_time))
                
                if [[ $time_diff -lt 3600 ]]; then
                    created_files+=("$file")
                fi
            done < <(find "$path" -type f -print0 2>/dev/null)
        fi
    done
    
    # Export for use by other functions
    printf '%s\n' "${created_files[@]}"
}

# Function to validate file locations
validate_file_locations() {
    local agent_num="$1"
    local files=("$@")
    
    echo "📁 Validating file locations..."
    
    local location_violations=()
    local correct_files=()
    
    for file in "${files[@]}"; do
        # Check if file is in allowed locations
        if [[ "$file" == "$WORKSPACE_PATH"* ]] || [[ "$file" == "$TEST_PATH"* ]] || [[ "$file" == "workspace/"* ]]; then
            correct_files+=("$file")
            echo "  ✓ $file (correct location)"
        else
            location_violations+=("$file")
            echo "  ❌ $file (wrong location - should be in $WORKSPACE_PATH or $TEST_PATH)"
        fi
    done
    
    if [[ ${#location_violations[@]} -gt 0 ]]; then
        echo "WARNING: ${#location_violations[@]} files in incorrect locations"
        printf "  - %s\n" "${location_violations[@]}"
    else
        echo "✓ All files in correct locations"
    fi
    
    echo "✓ File location validation completed"
}

# Function to check file size compliance (500 line limit)
check_file_size_compliance() {
    local agent_num="$1"
    local files=("$@")
    
    echo "📏 Checking file size compliance (500 line limit)..."
    
    local oversized_files=()
    local compliant_files=()
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local line_count=$(wc -l < "$file" 2>/dev/null)
            
            if [[ $line_count -gt 500 ]]; then
                oversized_files+=("$file:$line_count")
                echo "  ❌ $file ($line_count lines - EXCEEDS LIMIT)"
            else
                compliant_files+=("$file")
                echo "  ✓ $file ($line_count lines)"
            fi
        fi
    done
    
    if [[ ${#oversized_files[@]} -gt 0 ]]; then
        echo
        echo "🛑 HALT: Code size violation detected. A refactoring task is required."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "REFACTORING TASK FOR CLAUDE CODE (ORCHESTRATOR)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo
        echo "## Mission: Refactor Oversized File(s)"
        echo
        echo "You are the Orchestrator. The previous Sub-Agent generated code that violates our 500-line limit."
        echo "Your task is to refactor the following file(s) into smaller, logical modules while preserving all functionality."
        echo
        
        for oversized_file_info in "${oversized_files[@]}"; do
            # Extract file path and line count
            local file_path=$(echo "$oversized_file_info" | cut -d: -f1)
            local line_count=$(echo "$oversized_file_info" | cut -d: -f2)

            echo "---BEGIN REFACTORING PROMPT for $file_path---"
            echo
            echo "### Refactor Task: $file_path ($line_count lines)"
            echo
            echo "**Objective**: Split this file into smaller, logical modules. The goal is to improve maintainability by ensuring no single file exceeds 500 lines."
            echo
            echo "#### Critical Refactoring Rules:"
            echo "1.  **Preserve Logic**: You MUST NOT add, remove, or change the existing code's logic. This is a pure refactoring task."
            echo "2.  **Logical Cohesion**: Split the code based on functionality (e.g., separate classes into different files, group related utility functions)."
            echo "3.  **Update Imports**: After creating new files, you MUST update all imports. This includes fixing imports in the newly created files and updating any other files that were importing from the original, now-refactored file."
            echo "4.  **File Naming**: Give new files clear, descriptive names that reflect their content."
            echo "5.  **Location**: Place new files in a logical location within the existing directory structure."
            echo
            echo "#### File Content to Refactor:"
            echo '```python'
            cat "$file_path"
            echo '```'
            echo
            echo "#### Post-Refactoring Validation:"
            echo "After you have completed the refactoring, you MUST run the relevant tests to ensure you have not introduced any regressions. Start with the tests related to the original file, then run the full unit test suite."
            echo
            echo "Example validation command:"
            echo "  `pytest workspace/[projectname]/tests/unit/`"
            echo
            echo "---END REFACTORING PROMPT for $file_path---"
            echo
        done

        echo "Please execute the refactoring task(s) above. Once complete and all tests pass, re-run the `validate-file-structure.sh` script to confirm compliance before proceeding."
        exit 2 # Exit with a special code to signify a required manual intervention
    else
        echo "✓ All files comply with 500-line limit"
    fi
    
    echo "✓ File size compliance check completed"
}

# Function to validate file extensions
validate_file_extensions() {
    local agent_num="$1"
    local files=("$@")
    
    echo "🔧 Validating file extensions for $LANGUAGE..."
    
    local extension_violations=()
    local correct_extensions=()
    
    # Convert FILE_EXTENSIONS to array
    IFS=',' read -ra expected_extensions <<< "$FILE_EXTENSIONS"
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            local file_ext=""
            if [[ "$file" == *.* ]]; then
                file_ext=".${file##*.}"
            fi
            
            local extension_ok=false
            for ext in "${expected_extensions[@]}"; do
                ext=$(echo "$ext" | xargs)  # Trim whitespace
                if [[ "$file_ext" == "$ext" ]] || [[ "$ext" == "*" ]]; then
                    extension_ok=true
                    break
                fi
            done
            
            if [[ "$extension_ok" == true ]]; then
                correct_extensions+=("$file")
                echo "  ✓ $file ($file_ext)"
            else
                extension_violations+=("$file")
                echo "  ❌ $file ($file_ext - expected: $FILE_EXTENSIONS)"
            fi
        fi
    done
    
    if [[ ${#extension_violations[@]} -gt 0 ]]; then
        echo "WARNING: ${#extension_violations[@]} files with unexpected extensions"
        printf "  - %s\n" "${extension_violations[@]}"
    else
        echo "✓ All files have correct extensions"
    fi
    
    echo "✓ File extension validation completed"
}

# Function to validate test file structure
validate_test_structure() {
    local agent_num="$1"
    local files=("$@")
    
    echo "🧪 Validating test file structure..."
    
    local test_files=()
    local source_files=()
    
    # Separate test files from source files
    for file in "${files[@]}"; do
        if [[ "$file" == "$TEST_PATH"* ]]; then
            test_files+=("$file")
        elif [[ "$file" == "$WORKSPACE_PATH"* ]]; then
            source_files+=("$file")
        fi
    done
    
    echo "  📄 Source files: ${#source_files[@]}"
    echo "  🧪 Test files: ${#test_files[@]}"
    
    # Check test coverage expectations
    if [[ ${#source_files[@]} -gt 0 ]] && [[ ${#test_files[@]} -eq 0 ]]; then
        echo "  ⚠️  WARNING: Source files created but no test files found"
        echo "     Consider adding tests for the implemented components"
    elif [[ ${#test_files[@]} -gt 0 ]]; then
        echo "  ✓ Test files created for this component"
    fi
    
    # Validate test file naming conventions based on language
    case "$LANGUAGE" in
        "Python")
            for test_file in "${test_files[@]}"; do
                if [[ "$(basename "$test_file")" == test_* ]] || [[ "$(basename "$test_file")" == *_test.py ]]; then
                    echo "  ✓ $test_file (follows Python test naming)"
                else
                    echo "  ⚠️  $test_file (consider test_ prefix or _test suffix)"
                fi
            done
            ;;
        "JavaScript/TypeScript"|"JavaScript"|"TypeScript")
            for test_file in "${test_files[@]}"; do
                if [[ "$(basename "$test_file")" == *.test.* ]] || [[ "$(basename "$test_file")" == *.spec.* ]]; then
                    echo "  ✓ $test_file (follows JS/TS test naming)"
                else
                    echo "  ⚠️  $test_file (consider .test. or .spec. naming)"
                fi
            done
            ;;
        "Rust")
            for test_file in "${test_files[@]}"; do
                echo "  ✓ $test_file (Rust test structure)"
            done
            ;;
        *)
            for test_file in "${test_files[@]}"; do
                echo "  ✓ $test_file (test file present)"
            done
            ;;
    esac
    
    echo "✓ Test structure validation completed"
}

# Function to check for required project files
check_project_files() {
    local agent_num="$1"
    
    echo "📋 Checking for required project files..."
    
    local required_files=()
    local missing_files=()
    
    # Check for project-specific required files
    case "$PROJECT_TYPE" in
        "python")
            required_files=("workspace/requirements.txt")
            ;;
        "nodejs")
            required_files=("workspace/package.json")
            ;;
        "rust")
            required_files=("workspace/Cargo.toml")
            ;;
        "go")
            required_files=("workspace/go.mod")
            ;;
        "java")
            required_files=("workspace/pom.xml")
            ;;
        "cpp")
            required_files=("workspace/CMakeLists.txt")
            ;;
        *)
            required_files=()
            ;;
    esac
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "  ✓ $file (required file present)"
        else
            missing_files+=("$file")
            echo "  ❌ $file (required file missing)"
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        echo "WARNING: ${#missing_files[@]} required files missing"
    else
        echo "✓ All required project files present"
    fi
    
    echo "✓ Project files check completed"
}

# Function to create file structure report
create_file_structure_report() {
    local agent_num="$1"
    local files=("$@")
    
    echo "📊 Creating file structure report..."
    
    local report_file="workspace/workflow/file-structure-agent-${agent_num}.md"
    
    cat > "$report_file" << EOF
# File Structure Report for Agent $agent_num

**Date**: $(date)
**Project Type**: $PROJECT_TYPE
**Language**: $LANGUAGE
**Workspace**: $WORKSPACE_PATH
**Test Directory**: $TEST_PATH

## Files Created/Modified
$(printf "- %s\n" "${files[@]}")

## Structure Validation

### Location Compliance
$(validate_file_locations "$agent_num" "${files[@]}" 2>&1)

### Size Compliance (500-line limit)
$(check_file_size_compliance "$agent_num" "${files[@]}" 2>&1)

### Extension Compliance
$(validate_file_extensions "$agent_num" "${files[@]}" 2>&1)

### Test Structure
$(validate_test_structure "$agent_num" "${files[@]}" 2>&1)

### Project Files
$(check_project_files "$agent_num" 2>&1)

## Summary
- **Total Files**: ${#files[@]}
- **Workspace Files**: $(printf "%s\n" "${files[@]}" | grep -c "$WORKSPACE_PATH" || echo "0")
- **Test Files**: $(printf "%s\n" "${files[@]}" | grep -c "$TEST_PATH" || echo "0")
- **Compliance Status**: Review above sections for any violations

## Recommendations
- Ensure all files remain under 500 lines
- Add tests for any source files without corresponding tests  
- Follow $LANGUAGE naming conventions for consistency
EOF
    
    echo "✓ File structure report created: $report_file"
}

# Function to validate the file structure validation
validate_structure_validation() {
    local agent_num="$1"
    
    echo "✅ Validating file structure validation..."
    
    # Check that report was created
    if [[ ! -f "workspace/workflow/file-structure-agent-${agent_num}.md" ]]; then
        echo "WARNING: File structure report was not created"
    fi
    
    echo "✓ File structure validation validated"
}

# Function to log file structure validation
log_structure_validation() {
    local agent_num="$1"
    local file_count="$2"
    
    {
        echo "[$(date)] File structure validation completed for Agent $agent_num"
        echo "[$(date)] Validated $file_count files"
        echo "[$(date)] Structure compliance checked"
    } >> workspace/workflow/execution.log
    
    echo "✓ File structure validation logged"
}

# Main file structure validation function
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FILE STRUCTURE VALIDATION PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Validate environment
    validate_environment
    
    echo "📁 Validating file structure for Agent $AGENT_NUM..."
    echo "🔧 Project Type: $PROJECT_TYPE"
    echo "💻 Language: $LANGUAGE"
    echo "📁 Workspace: $WORKSPACE_PATH"
    echo "🧪 Test Path: $TEST_PATH"
    
    # Find files created by this agent
    local agent_files=()
    mapfile -t agent_files < <(find_agent_files "$AGENT_NUM")
    
    echo "📄 Found ${#agent_files[@]} files to validate"
    
    if [[ ${#agent_files[@]} -eq 0 ]]; then
        echo "⚠️  WARNING: No recently modified files found"
        echo "   This might indicate the agent didn't create any files"
    else
        # Perform all validation checks
        validate_file_locations "$AGENT_NUM" "${agent_files[@]}"
        check_file_size_compliance "$AGENT_NUM" "${agent_files[@]}"
        validate_file_extensions "$AGENT_NUM" "${agent_files[@]}"
        validate_test_structure "$AGENT_NUM" "${agent_files[@]}"
        check_project_files "$AGENT_NUM"
        
        # Create report
        create_file_structure_report "$AGENT_NUM" "${agent_files[@]}"
    fi
    
    # Validate the validation
    validate_structure_validation "$AGENT_NUM"
    
    # Log the validation
    log_structure_validation "$AGENT_NUM" "${#agent_files[@]}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "FILE STRUCTURE VALIDATION COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi