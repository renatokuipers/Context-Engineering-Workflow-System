#!/bin/bash

# finalize-prp.sh
# Purpose: Pure orchestration - deploy Final QA Sub-Agent
# Philosophy: Scripts orchestrate, LLMs generate content

echo "=== PRP Generation: Final QA Orchestration ==="
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
    echo "🎯 Starting final QA orchestration..."
    
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
    
    # Generate focused micro-prompt for final QA
    build_final_qa_prompt "$PROJECT_NAME" "$PROJECT_SLUG"
    
    echo
    echo "---END SUB-AGENT PROMPT---"
    echo
    echo "=== ORCHESTRATOR SUMMARY ==="
    echo "✓ Prerequisites validated"
    echo "✓ Micro-prompt generated for Final QA Sub-Agent"
    echo "✓ Ready for Sub-Agent deployment"
    echo
    echo "The Sub-Agent will:"
    echo "- Perform final quality assurance on the complete PRP"
    echo "- Validate workspace references are consistent (workspace/$PROJECT_SLUG/)"
    echo "- Check implementation readiness"
    echo "- Add final touches and executive summary"
    echo "- Assess confidence level for implementation readiness"
    echo
    echo "=== PRP GENERATION COMPLETE ==="
    echo "After the Final QA Sub-Agent completes, the PRP will be ready for implementation!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi