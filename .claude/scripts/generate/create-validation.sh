#!/bin/bash

# create-validation.sh
# Purpose: Pure orchestration - deploy Validation Strategy Sub-Agent
# Philosophy: Scripts orchestrate, LLMs generate content

echo "=== PRP Generation: Validation Strategy Orchestration ==="
echo

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared/context_gatherer.sh"
source "$SCRIPT_DIR/shared/prompt_builder.sh"

# Function to validate prerequisites
validate_prerequisites() {
    # Extract project context to get PROJECT_NAME
    if ! extract_project_context; then
        echo "❌ Context extraction failed"
        exit 1
    fi
    
    local prp_file="PRPs/PRP_$PROJECT_NAME.md"
    
    if [[ ! -f "$prp_file" ]]; then
        echo "❌ ERROR: PRP file not found: $prp_file"
        echo "Please run the previous scripts first to generate and enhance the PRP."
        exit 1
    fi
    
    echo "✓ Prerequisites validated"
    echo "✓ PRP file found: $prp_file"
}

# Main execution function
main() {
    echo "🎯 Starting validation strategy orchestration..."
    
    # Validate prerequisites and extract context
    validate_prerequisites
    
    echo
    echo "=== PROJECT CONTEXT SUMMARY ==="
    echo "Project Name: $PROJECT_NAME"
    echo "Project Slug: $PROJECT_SLUG"
    echo "Languages: $DETECTED_LANGUAGES"
    echo "Workspace: workspace/$PROJECT_SLUG/"
    echo
    
    echo "=== SUB-AGENT DEPLOYMENT ==="
    echo "Deploy the following Sub-Agent with this exact prompt:"
    echo
    echo "---BEGIN SUB-AGENT PROMPT---"
    
    # Generate focused micro-prompt for validation strategy
    build_validation_strategy_prompt "$PROJECT_NAME" "$PROJECT_SLUG" "$DETECTED_LANGUAGES"
    
    echo
    echo "---END SUB-AGENT PROMPT---"
    echo
    echo "=== ORCHESTRATOR SUMMARY ==="
    echo "✓ Prerequisites validated"
    echo "✓ Micro-prompt generated for Validation Strategy Sub-Agent"
    echo "✓ Ready for Sub-Agent deployment"
    echo
    echo "The Sub-Agent will:"
    echo "- Design comprehensive validation approach for the implementation"
    echo "- Create validation levels (syntax, unit tests, integration tests)"
    echo "- Define specific test cases based on implementation requirements"
    echo "- Set validation commands using workspace/$PROJECT_SLUG/ paths"
    echo "- Prepare the PRP for final QA"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi