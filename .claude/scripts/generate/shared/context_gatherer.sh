#!/bin/bash

# context_gatherer.sh
# Purpose: Pure context extraction from project files
# Philosophy: Gather context, don't generate content

# Global variables for extracted context
PROJECT_NAME=""
PROJECT_SLUG=""
INITIAL_CONTENT=""
PROJECT_DOCS=""
README_CONTENT=""
PROJECT_FILES=""
DETECTED_LANGUAGES=""

# Function to extract intelligent project name
extract_intelligent_name() {
    local name=""
    
    # Priority 1: INITIAL.md first heading
    if [[ -f "INITIAL.md" ]]; then
        name=$(grep -m1 "^# " INITIAL.md | sed 's/^# //' | sed 's/[^a-zA-Z0-9 ]//g' | awk '{print $1}')
    fi
    
    # Priority 2: docs/project.md first heading
    if [[ -z "$name" && -f "docs/project.md" ]]; then
        name=$(grep -m1 "^# " docs/project.md | sed 's/^# //' | sed 's/[^a-zA-Z0-9 ]//g' | awk '{print $1}')
    fi
    
    # Priority 3: Any docs/*.md first heading
    if [[ -z "$name" && -d "docs" ]]; then
        name=$(find docs/ -name "*.md" -exec grep -m1 "^# " {} \; | head -1 | sed 's/^# //' | sed 's/[^a-zA-Z0-9 ]//g' | awk '{print $1}')
    fi
    
    # Priority 4: Directory name as fallback
    if [[ -z "$name" ]]; then
        name=$(basename "$(pwd)" | sed 's/[^a-zA-Z0-9]//g')
    fi
    
    echo "$name"
}

# Function to generate project slug from name
generate_project_slug() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

# Function to extract project context from files
extract_project_context() {
    echo "🔍 Extracting project context..."
    
    # Extract project name and slug
    PROJECT_NAME=$(extract_intelligent_name)
    PROJECT_SLUG=$(generate_project_slug "$PROJECT_NAME")
    
    # Extract content from key files
    if [[ -f "INITIAL.md" ]]; then
        INITIAL_CONTENT=$(cat INITIAL.md)
        echo "✓ INITIAL.md content extracted ($(wc -l < INITIAL.md) lines)"
    else
        echo "ℹ No INITIAL.md found"
        INITIAL_CONTENT=""
    fi
    
    # Extract documentation content
    if [[ -d "docs" ]]; then
        PROJECT_DOCS=$(find docs/ -name "*.md" -exec cat {} \; 2>/dev/null | head -1000)
        local doc_count=$(find docs/ -name "*.md" | wc -l)
        echo "✓ Documentation extracted from $doc_count files"
    else
        echo "ℹ No docs/ directory found"
        PROJECT_DOCS=""
    fi
    
    # Extract README content
    if [[ -f "README.md" ]]; then
        README_CONTENT=$(cat README.md)
        echo "✓ README.md content extracted ($(wc -l < README.md) lines)"
    else
        echo "ℹ No README.md found"
        README_CONTENT=""
    fi
    
    # Detect project files and languages
    detect_project_files
    
    echo "✓ Context extraction complete"
    echo "  Project Name: $PROJECT_NAME"
    echo "  Project Slug: $PROJECT_SLUG"
    echo "  Languages: $DETECTED_LANGUAGES"
}

# Function to detect project files and languages
detect_project_files() {
    echo "🔍 Detecting project files and languages..."
    
    # Get a sample of project files (excluding common noise)
    PROJECT_FILES=$(find . -type f \( \
        -name "*.py" -o \
        -name "*.js" -o \
        -name "*.ts" -o \
        -name "*.rs" -o \
        -name "*.cpp" -o \
        -name "*.c" -o \
        -name "*.java" -o \
        -name "*.go" -o \
        -name "*.php" -o \
        -name "*.rb" -o \
        -name "*.swift" -o \
        -name "*.kt" -o \
        -name "*.html" -o \
        -name "*.css" -o \
        -name "*.scss" -o \
        -name "*.vue" -o \
        -name "*.jsx" -o \
        -name "*.tsx" \
        \) \
        | grep -v __pycache__ \
        | grep -v node_modules \
        | grep -v .git \
        | grep -v venv \
        | grep -v .pytest_cache \
        | head -20)
    
    # Detect languages based on files and config files
    DETECTED_LANGUAGES=""
    
    # Python detection
    if [[ -f "requirements.txt" || -f "pyproject.toml" || -f "setup.py" || -f "Pipfile" ]] || echo "$PROJECT_FILES" | grep -q "\.py$"; then
        DETECTED_LANGUAGES="$DETECTED_LANGUAGES Python,"
    fi
    
    # Node.js detection
    if [[ -f "package.json" ]] || echo "$PROJECT_FILES" | grep -q "\.js$\|\.ts$"; then
        DETECTED_LANGUAGES="$DETECTED_LANGUAGES JavaScript/TypeScript,"
    fi
    
    # Rust detection
    if [[ -f "Cargo.toml" ]] || echo "$PROJECT_FILES" | grep -q "\.rs$"; then
        DETECTED_LANGUAGES="$DETECTED_LANGUAGES Rust,"
    fi
    
    # C++ detection
    if [[ -f "CMakeLists.txt" || -f "Makefile" ]] || echo "$PROJECT_FILES" | grep -q "\.cpp$\|\.c$"; then
        DETECTED_LANGUAGES="$DETECTED_LANGUAGES C/C++,"
    fi
    
    # Web detection
    if echo "$PROJECT_FILES" | grep -q "\.html$\|\.css$\|\.scss$\|\.vue$"; then
        DETECTED_LANGUAGES="$DETECTED_LANGUAGES Web,"
    fi
    
    # Clean up languages string
    DETECTED_LANGUAGES=$(echo "$DETECTED_LANGUAGES" | sed 's/,$//')
    
    # Fallback if no languages detected
    if [[ -z "$DETECTED_LANGUAGES" ]]; then
        DETECTED_LANGUAGES="Generic"
    fi
    
    echo "✓ Project files detected: $(echo "$PROJECT_FILES" | wc -l) files"
    echo "✓ Languages detected: $DETECTED_LANGUAGES"
}

# Function to get combined project context for prompts
get_combined_context() {
    echo "=== PROJECT CONTEXT ==="
    echo "Project Name: $PROJECT_NAME"
    echo "Project Slug: $PROJECT_SLUG"
    echo "Languages: $DETECTED_LANGUAGES"
    echo ""
    echo "=== INITIAL.md CONTENT ==="
    echo "$INITIAL_CONTENT"
    echo ""
    echo "=== DOCUMENTATION CONTENT ==="
    echo "$PROJECT_DOCS"
    echo ""
    echo "=== PROJECT FILES ==="
    echo "$PROJECT_FILES"
}

# Function to validate extracted context
validate_context() {
    local errors=0
    
    if [[ -z "$PROJECT_NAME" ]]; then
        echo "❌ ERROR: Could not extract project name"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$PROJECT_SLUG" ]]; then
        echo "❌ ERROR: Could not generate project slug"
        errors=$((errors + 1))
    fi
    
    if [[ -z "$INITIAL_CONTENT" && -z "$PROJECT_DOCS" && -z "$README_CONTENT" ]]; then
        echo "❌ ERROR: No project documentation found (INITIAL.md, docs/, or README.md)"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        echo "❌ Context extraction failed with $errors errors"
        return 1
    fi
    
    echo "✅ Context validation passed"
    return 0
}

# Main function to extract all context
main() {
    echo "=== Pure Context Extraction ==="
    extract_project_context
    
    if validate_context; then
        echo ""
        echo "=== Context Summary ==="
        echo "Project Name: $PROJECT_NAME"
        echo "Project Slug: $PROJECT_SLUG"
        echo "Languages: $DETECTED_LANGUAGES"
        echo "Content Sources: $([ -n "$INITIAL_CONTENT" ] && echo "INITIAL.md ")$([ -n "$PROJECT_DOCS" ] && echo "docs/ ")$([ -n "$README_CONTENT" ] && echo "README.md")"
        echo "Files Detected: $(echo "$PROJECT_FILES" | wc -l)"
        return 0
    else
        return 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi