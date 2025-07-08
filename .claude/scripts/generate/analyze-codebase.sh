#!/bin/bash

# analyze-codebase.sh
# Purpose: Pure orchestration - analyze codebase and deploy Codebase Analysis Sub-Agent
# Philosophy: Scripts orchestrate, LLMs generate content

echo "=== PRP Generation: Codebase Analysis Orchestration ==="
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
        echo "Please run gather-project-context.sh first to generate the base PRP."
        exit 1
    fi
    
    echo "✓ Prerequisites validated"
    echo "✓ PRP file found: $prp_file"
}

# Main execution function
main() {
    echo "🎯 Starting codebase analysis orchestration..."
    
    # Validate prerequisites and extract context
    validate_prerequisites
    
    echo
    echo "=== PROJECT CONTEXT SUMMARY ==="
    echo "Project Name: $PROJECT_NAME"
    echo "Project Slug: $PROJECT_SLUG"
    echo "Languages: $DETECTED_LANGUAGES"
    echo "Workspace: workspace/$PROJECT_SLUG/"
    echo "Files Detected: $(echo "$PROJECT_FILES" | wc -l)"
    echo
    
    echo "=== SUB-AGENT DEPLOYMENT ==="
    echo "Deploy the following Sub-Agent with this exact prompt:"
    echo
    echo "---BEGIN SUB-AGENT PROMPT---"
    
    # Generate focused micro-prompt for codebase analysis
    build_codebase_analysis_prompt "$PROJECT_NAME" "$PROJECT_SLUG" "$PROJECT_FILES"
    
    echo
    echo "---END SUB-AGENT PROMPT---"
    echo
    echo "=== ORCHESTRATOR SUMMARY ==="
    echo "✓ Codebase structure analyzed ($(echo "$PROJECT_FILES" | wc -l) files)"
    echo "✓ Project context validated"
    echo "✓ Micro-prompt generated for Codebase Analysis Sub-Agent"
    echo "✓ Ready for Sub-Agent deployment"
    echo
    echo "The Sub-Agent will:"
    echo "- Scan the existing codebase for patterns and conventions"
    echo "- Enhance the PRP's 'Known Gotchas & Library Quirks' section"
    echo "- Update file references to use workspace/$PROJECT_SLUG/ prefix"
    echo "- Add specific code examples from the existing codebase"
    echo "- Prepare the PRP for the next stage (external research)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi