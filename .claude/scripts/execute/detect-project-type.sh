#!/bin/bash

# Project Type Detection Script
# This script detects the project type and sets appropriate environment variables

# Function to detect project type based on files present
detect_project_type() {
    local project_root="${1:-.}"
    
    # Check for Python project indicators
    if [[ -f "$project_root/setup.py" ]] || [[ -f "$project_root/pyproject.toml" ]] || [[ -f "$project_root/requirements.txt" ]] || [[ -f "$project_root/Pipfile" ]]; then
        echo "python"
        return 0
    fi
    
    # Check for Node.js project indicators
    if [[ -f "$project_root/package.json" ]] || [[ -f "$project_root/package-lock.json" ]] || [[ -f "$project_root/yarn.lock" ]]; then
        echo "nodejs"
        return 0
    fi
    
    # Check for Rust project indicators
    if [[ -f "$project_root/Cargo.toml" ]]; then
        echo "rust"
        return 0
    fi
    
    # Check for Go project indicators
    if [[ -f "$project_root/go.mod" ]] || [[ -f "$project_root/go.sum" ]]; then
        echo "go"
        return 0
    fi
    
    # Check for Java project indicators
    if [[ -f "$project_root/pom.xml" ]] || [[ -f "$project_root/build.gradle" ]] || [[ -f "$project_root/build.gradle.kts" ]]; then
        echo "java"
        return 0
    fi
    
    # Check for C/C++ project indicators
    if [[ -f "$project_root/CMakeLists.txt" ]] || [[ -f "$project_root/Makefile" ]]; then
        echo "cpp"
        return 0
    fi
    
    # Check for web project indicators
    if [[ -f "$project_root/index.html" ]] || [[ -d "$project_root/public" ]] || [[ -d "$project_root/src" && -f "$project_root/src/index.html" ]]; then
        echo "web"
        return 0
    fi
    
    # Check for Docker project
    if [[ -f "$project_root/Dockerfile" ]] || [[ -f "$project_root/docker-compose.yml" ]]; then
        echo "docker"
        return 0
    fi
    
    # Default to generic if nothing matches
    echo "generic"
}

# Function to set project-specific environment variables
set_project_env() {
    local project_type="$1"
    
    case "$project_type" in
        "python")
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="requirements.txt"
            export BUILD_COMMAND="python -m pytest"
            export LINT_COMMAND="python -m flake8"
            export TYPE_CHECK_COMMAND="python -m mypy"
            export INSTALL_COMMAND="pip install -r requirements.txt"
            export RUN_COMMAND="python"
            export FILE_EXTENSIONS=".py"
            export LANGUAGE="Python"
            export FRAMEWORK_HINTS="Use type hints, Pydantic for data models, pytest for testing"
            export PERFORMANCE_HINTS="Consider memory usage, use async/await for I/O operations"
            ;;
        "nodejs")
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="package.json"
            export BUILD_COMMAND="npm run build"
            export LINT_COMMAND="npm run lint"
            export TYPE_CHECK_COMMAND="npm run type-check"
            export INSTALL_COMMAND="npm install"
            export RUN_COMMAND="npm start"
            export FILE_EXTENSIONS=".js,.ts,.jsx,.tsx"
            export LANGUAGE="JavaScript/TypeScript"
            export FRAMEWORK_HINTS="Use TypeScript, modern ES6+ features, proper error handling"
            export PERFORMANCE_HINTS="Consider bundle size, use code splitting, optimize async operations"
            ;;
        "rust")
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="Cargo.toml"
            export BUILD_COMMAND="cargo build"
            export LINT_COMMAND="cargo clippy"
            export TYPE_CHECK_COMMAND="cargo check"
            export INSTALL_COMMAND="cargo fetch"
            export RUN_COMMAND="cargo run"
            export FILE_EXTENSIONS=".rs"
            export LANGUAGE="Rust"
            export FRAMEWORK_HINTS="Use proper error handling with Result<>, follow Rust conventions"
            export PERFORMANCE_HINTS="Use zero-cost abstractions, consider memory allocation patterns"
            ;;
        "go")
            export WORKSPACE_NAME="."
            export TEST_DIR="."
            export DEPENDENCIES_FILE="go.mod"
            export BUILD_COMMAND="go build"
            export LINT_COMMAND="golint"
            export TYPE_CHECK_COMMAND="go vet"
            export INSTALL_COMMAND="go mod download"
            export RUN_COMMAND="go run"
            export FILE_EXTENSIONS=".go"
            export LANGUAGE="Go"
            export FRAMEWORK_HINTS="Follow Go conventions, use interfaces, proper error handling"
            export PERFORMANCE_HINTS="Consider goroutines and channels, profile memory usage"
            ;;
        "java")
            export WORKSPACE_NAME="src/main/java"
            export TEST_DIR="src/test/java"
            export DEPENDENCIES_FILE="pom.xml"
            export BUILD_COMMAND="mvn compile"
            export LINT_COMMAND="mvn checkstyle:check"
            export TYPE_CHECK_COMMAND="mvn compile"
            export INSTALL_COMMAND="mvn dependency:resolve"
            export RUN_COMMAND="mvn exec:java"
            export FILE_EXTENSIONS=".java"
            export LANGUAGE="Java"
            export FRAMEWORK_HINTS="Use proper OOP principles, handle exceptions, follow Java conventions"
            export PERFORMANCE_HINTS="Consider JVM tuning, use appropriate data structures"
            ;;
        "cpp")
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="CMakeLists.txt"
            export BUILD_COMMAND="cmake --build build"
            export LINT_COMMAND="cppcheck"
            export TYPE_CHECK_COMMAND="cmake --build build"
            export INSTALL_COMMAND="cmake .."
            export RUN_COMMAND="./build/main"
            export FILE_EXTENSIONS=".cpp,.hpp,.h"
            export LANGUAGE="C++"
            export FRAMEWORK_HINTS="Use modern C++ features, RAII, smart pointers"
            export PERFORMANCE_HINTS="Consider memory management, use appropriate algorithms"
            ;;
        "web")
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="package.json"
            export BUILD_COMMAND="npm run build"
            export LINT_COMMAND="npm run lint"
            export TYPE_CHECK_COMMAND="npm run validate"
            export INSTALL_COMMAND="npm install"
            export RUN_COMMAND="npm start"
            export FILE_EXTENSIONS=".html,.css,.js,.ts"
            export LANGUAGE="Web (HTML/CSS/JavaScript)"
            export FRAMEWORK_HINTS="Use semantic HTML, responsive CSS, modern JavaScript"
            export PERFORMANCE_HINTS="Optimize bundle size, use lazy loading, consider accessibility"
            ;;
        "docker")
            export WORKSPACE_NAME="."
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="Dockerfile"
            export BUILD_COMMAND="docker build -t app ."
            export LINT_COMMAND="hadolint Dockerfile"
            export TYPE_CHECK_COMMAND="docker build --dry-run -t app ."
            export INSTALL_COMMAND="docker pull"
            export RUN_COMMAND="docker run app"
            export FILE_EXTENSIONS=".dockerfile,.yml,.yaml"
            export LANGUAGE="Docker"
            export FRAMEWORK_HINTS="Use multi-stage builds, minimize layers, security best practices"
            export PERFORMANCE_HINTS="Optimize image size, use appropriate base images"
            ;;
        "generic"|*)
            export WORKSPACE_NAME="src"
            export TEST_DIR="tests"
            export DEPENDENCIES_FILE="requirements.txt"
            export BUILD_COMMAND="python -m pytest"
            export LINT_COMMAND="python -m flake8"
            export TYPE_CHECK_COMMAND="python -m mypy"
            export INSTALL_COMMAND="pip install -r requirements.txt"
            export RUN_COMMAND="python"
            export FILE_EXTENSIONS=".py"
            export LANGUAGE="Python"
            export FRAMEWORK_HINTS="Use type hints, Pydantic for data models, pytest for testing"
            export PERFORMANCE_HINTS="Consider memory usage, use async/await for I/O operations"
            ;;
    esac
    
    PROJECT_NAME_FROM_PRP=$(basename "$PRP_PATH" .md | sed 's/PRP_//')
    PROJECT_SLUG=$(echo "$PROJECT_NAME_FROM_PRP" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    # Set derived variables
    export PROJECT_TYPE="$project_type"
    export WORKSPACE_PATH="workspace/$PROJECT_SLUG"
    export TEST_PATH="workspace/$PROJECT_SLUG/tests"
    
    # Create directories if they don't exist
    mkdir -p "$WORKSPACE_PATH"
    mkdir -p "$TEST_PATH"
}

# Function to output detection results
output_detection_results() {
    cat << EOF
Project Type: $PROJECT_TYPE
Language: $LANGUAGE
workspace: $WORKSPACE_PATH
Test Directory: $TEST_PATH
Dependencies File: $DEPENDENCIES_FILE
Build Command: $BUILD_COMMAND
Run Command: $RUN_COMMAND
File Extensions: $FILE_EXTENSIONS
EOF
}

# Main execution
main() {
    local project_root="${1:-.}"
    
    # Detect project type
    local detected_type=$(detect_project_type "$project_root")
    
    # Set environment variables
    set_project_env "$detected_type"
    
    # Output results if requested
    if [[ "$2" == "--verbose" ]]; then
        output_detection_results
    fi
    
    # Export all variables for use by other scripts
    export PROJECT_TYPE WORKSPACE_NAME TEST_DIR DEPENDENCIES_FILE
    export BUILD_COMMAND LINT_COMMAND TYPE_CHECK_COMMAND INSTALL_COMMAND RUN_COMMAND
    export FILE_EXTENSIONS LANGUAGE FRAMEWORK_HINTS PERFORMANCE_HINTS
    export WORKSPACE_PATH TEST_PATH
}

# Run main function if script is executed directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
else
    # When sourced, run main with passed arguments
    main "$@"
fi