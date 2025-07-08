#!/bin/bash

# setup-workspace.sh - Detect project type and create directory structure
# This script detects the project type and sets up the workspace directories

# This ensures all paths are resolved from the true project root, not the current working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0 [project_root_override]"
    echo "  project_root_override: Optional path to analyze (defaults to script's calculated project root)"
    exit 1
}

# Function to detect and setup project environment
setup_project_environment() {
    local project_root="${1:-$PROJECT_ROOT}"
    
    echo "🔍 Detecting project type in: $project_root"
    
    local detection_script="$PROJECT_ROOT/.claude/scripts/execute/detect-project-type.sh"
    
    if [[ -f "$detection_script" ]]; then
        # This ensures any 'export' commands in the sourced script apply to *this* shell.
        source "$detection_script" "$project_root"
    else
        echo "ERROR: Project detection script not found: $detection_script"
        exit 1
    fi
    
    echo "✓ Project type detected: $PROJECT_TYPE ($LANGUAGE)"
}

# Function to create directory structure
create_directory_structure() {
    echo "📁 Creating directory structure based on PRP..."

    local directories=(
        "$PROJECT_ROOT/workspace/workflow"
        "$PROJECT_ROOT/$WORKSPACE_PATH"
        "$PROJECT_ROOT/$TEST_PATH"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            echo "✓ Created directory: $dir"
        else
            echo "ERROR: Failed to create directory: $dir"
            exit 1
        fi
    done
    
    # Create project-specific directories based on type
    case "$PROJECT_TYPE" in
        "python")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/tests"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/docs"
            echo "✓ Created Python-specific directories"
            ;;
        "nodejs")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/components"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/utils"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/public"
            echo "✓ Created Node.js-specific directories"
            ;;
        "java")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/main/java"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/test/java"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/main/resources"
            echo "✓ Created Java-specific directories"
            ;;
        "rust")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/bin"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/examples"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/benches"
            echo "✓ Created Rust-specific directories"
            ;;
        "go")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/cmd"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/pkg"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/internal"
            echo "✓ Created Go-specific directories"
            ;;
        "cpp")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/include"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/build"
            echo "✓ Created C++-specific directories"
            ;;
        "web")
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/css"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/src/js"
            mkdir -p "$PROJECT_ROOT/$WORKSPACE_PATH/assets"
            echo "✓ Created Web-specific directories"
            ;;
        *)
            echo "✓ Created generic project directories"
            ;;
    esac
}

# Function to create initial project files based on type
create_initial_files() {
    echo "📄 Creating initial project files..."
    
    case "$PROJECT_TYPE" in
        "python")
            # Create __init__.py files
            touch "$PROJECT_ROOT/$WORKSPACE_PATH/src/__init__.py"
            touch "$PROJECT_ROOT/$WORKSPACE_PATH/tests/__init__.py"
            
            # Create requirements.txt if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/requirements.txt" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/requirements.txt" << EOF
# Project dependencies
# Add your package requirements here
EOF
                echo "✓ Created requirements.txt"
            fi
            ;;
        "nodejs")
            # Create package.json if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/package.json" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/package.json" << EOF
{
  "name": "project",
  "version": "1.0.0",
  "description": "",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "npm test",
    "build": "npm run build",
    "lint": "eslint src/"
  },
  "dependencies": {},
  "devDependencies": {}
}
EOF
                echo "✓ Created package.json"
            fi
            ;;
        "rust")
            # Create Cargo.toml if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/Cargo.toml" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/Cargo.toml" << EOF
[package]
name = "project"
version = "0.1.0"
edition = "2021"

[dependencies]

[dev-dependencies]
EOF
                echo "✓ Created Cargo.toml"
            fi
            ;;
        "go")
            # Create go.mod if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/go.mod" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/go.mod" << EOF
module project

go 1.21

require ()
EOF
                echo "✓ Created go.mod"
            fi
            ;;
        "java")
            # Create pom.xml if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/pom.xml" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>project</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>
    
    <dependencies>
    </dependencies>
</project>
EOF
                echo "✓ Created pom.xml"
            fi
            ;;
        "cpp")
            # Create CMakeLists.txt if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/CMakeLists.txt" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.16)
project(project VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add executable
add_executable(project src/main.cpp)

# Include directories
target_include_directories(project PRIVATE include)
EOF
                echo "✓ Created CMakeLists.txt"
            fi
            ;;
        "web")
            # Create basic HTML file if it doesn't exist
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/index.html" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project</title>
    <link rel="stylesheet" href="src/css/style.css">
</head>
<body>
    <h1>Welcome to the Project</h1>
    <script src="src/js/main.js"></script>
</body>
</html>
EOF
                echo "✓ Created index.html"
            fi
            ;;
        *)
            # Create generic dependencies file
            if [[ ! -f "$PROJECT_ROOT/$WORKSPACE_PATH/dependencies.txt" ]]; then
                cat > "$PROJECT_ROOT/$WORKSPACE_PATH/dependencies.txt" << EOF
# Project dependencies
# Add your dependencies here
EOF
                echo "✓ Created dependencies.txt"
            fi
            ;;
    esac
}

# Function to export environment variables for other scripts
export_environment() {
    echo "🔧 Exporting environment variables..."
    
    # Export all project-specific variables
    export PROJECT_TYPE WORKSPACE_NAME TEST_DIR DEPENDENCIES_FILE
    export BUILD_COMMAND LINT_COMMAND TYPE_CHECK_COMMAND INSTALL_COMMAND RUN_COMMAND
    export FILE_EXTENSIONS LANGUAGE FRAMEWORK_HINTS PERFORMANCE_HINTS
    export WORKSPACE_PATH TEST_PATH
    
    # Export directory paths using absolute paths
    export ABSOLUTE_PROJECT_ROOT="$PROJECT_ROOT"
    export ABSOLUTE_WORKFLOW_DIR="$PROJECT_ROOT/workspace/workflow"
    
    cat > "$PROJECT_ROOT/workspace/workflow/temp_env.sh" << EOF
#!/bin/bash
export PROJECT_TYPE="$PROJECT_TYPE"
export LANGUAGE="$LANGUAGE"
export FILE_EXTENSIONS="$FILE_EXTENSIONS"
export PRP_PATH="$PRP_PATH"
export WORKSPACE_PATH="$WORKSPACE_PATH"
export TEST_PATH="$TEST_PATH"
export PROJECT_ROOT="$PROJECT_ROOT"
export WORKFLOW_DIR="$PROJECT_ROOT/workspace/workflow"
export BUILD_COMMAND="$BUILD_COMMAND"
export LINT_COMMAND="$LINT_COMMAND"
export TYPE_CHECK_COMMAND="$TYPE_CHECK_COMMAND"
export INSTALL_COMMAND="$INSTALL_COMMAND"
export RUN_COMMAND="$RUN_COMMAND"
export DEPENDENCIES_FILE="$DEPENDENCIES_FILE"
export FRAMEWORK_HINTS="$FRAMEWORK_HINTS"
export PERFORMANCE_HINTS="$PERFORMANCE_HINTS"
EOF
    
    echo "✓ Environment variables exported"
}

# Function to log workspace setup
log_workspace_setup() {
    local log_file="$PROJECT_ROOT/workspace/workflow/setup.log"
    
    {
        echo "[$(date)] workspace Setup Started"
        echo "Project Type: $PROJECT_TYPE"
        echo "Language: $LANGUAGE"
        echo "workspace Path: $WORKSPACE_PATH"
        echo "Test Path: $TEST_PATH"
        echo "Dependencies File: $DEPENDENCIES_FILE"
        echo "Build Command: $BUILD_COMMAND"
        echo "File Extensions: $FILE_EXTENSIONS"
        echo "Setup Status: SUCCESS"
        echo "---"
    } >> "$log_file"
    
    echo "✓ workspace setup logged to: $log_file"
}

# Function to validate workspace setup
validate_workspace() {
    echo "✅ Validating workspace setup..."
    
    local required_dirs=(
        "$PROJECT_ROOT/workspace"
        "$PROJECT_ROOT/workspace/workflow"
        "$PROJECT_ROOT/$WORKSPACE_PATH"
        "$PROJECT_ROOT/$TEST_PATH"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            echo "ERROR: Required directory not found: $dir"
            exit 1
        fi
    done
    
    echo "✓ workspace validation successful"
}

# Main setup function
main() {
    cd "$PROJECT_ROOT"
    echo "✅ Changed working directory to project root: $PROJECT_ROOT"

    local project_root_override="${1:-$PROJECT_ROOT}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "WORKSPACE SETUP PHASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Detect project type and setup environment
    setup_project_environment "$project_root_override"
    
    # Create directory structure
    create_directory_structure
    
    # Create initial project files
    create_initial_files
    
    # Export environment variables
    export_environment
    
    # Validate workspace
    validate_workspace
    
    # Log workspace setup
    log_workspace_setup
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "WORKSPACE SETUP COMPLETE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi