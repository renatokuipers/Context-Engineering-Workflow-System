#!/bin/bash

# gather-project-context.sh
# Purpose: Pure orchestration - gather context and deploy initial content generation Sub-Agent
# Philosophy: Scripts orchestrate, LLMs generate content

echo "=== PRP Generation: Context Orchestration ==="
echo

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared/context_gatherer.sh"
source "$SCRIPT_DIR/shared/prompt_builder.sh"

# Create directories if they don't exist
mkdir -p "PRPs"

# Function to create base PRP from template
create_base_prp_from_template() {
    local project_name="$1"
    local project_slug="$2"
    local detected_languages="$3"
    local prp_file="$4"
    
    echo "📝 Creating base PRP from template..."
    
    # Copy template and replace placeholders
    cp "PRPs/templates/prp_base.md" "$prp_file"
    
    # Replace placeholders with actual values
    sed -i "s/{GENERATED_PROJECT_NAME}/$project_name/g" "$prp_file"
    sed -i "s/{generated_project_slug}/$project_slug/g" "$prp_file"
    sed -i "s/{DETECTED_LANGUAGE}/$detected_languages/g" "$prp_file"
    sed -i "s/{TIMESTAMP}/$(date)/g" "$prp_file"
    sed -i "s/{SOURCE_FILES_LIST}/INITIAL.md, docs\/*.md/g" "$prp_file"
    
    echo "✓ Base PRP created: $prp_file"
}

# Function to validate prerequisites
validate_prerequisites() {
    if [[ ! -f "PRPs/templates/prp_base.md" ]]; then
        echo "❌ ERROR: Base template not found: PRPs/templates/prp_base.md"
        echo "The PRP template system is not properly set up."
        exit 1
    fi
    
    if [[ ! -f "INITIAL.md" && ! -d "docs" ]]; then
        echo "❌ ERROR: No project documentation found!"
        echo "Please create either INITIAL.md or docs/ directory with project requirements."
        exit 1
    fi
    
    echo "✓ Prerequisites validated"
}

# Main execution function
main() {
    echo "🎯 Starting context orchestration..."
    
    # Validate prerequisites
    validate_prerequisites
    
    # Extract project context (pure extraction, no generation)
    if ! extract_project_context; then
        echo "❌ Context extraction failed"
        exit 1
    fi
    
    # Create base PRP from template
    PRP_FILE="PRPs/PRP_$PROJECT_NAME.md"
    create_base_prp_from_template "$PROJECT_NAME" "$PROJECT_SLUG" "$DETECTED_LANGUAGES" "$PRP_FILE"
    
    # Build context for the Initial Content Generation Sub-Agent
    COMBINED_CONTEXT=$(get_combined_context)
    
    echo
    echo "=== PROJECT CONTEXT SUMMARY ==="
    echo "Project Name: $PROJECT_NAME"
    echo "Project Slug: $PROJECT_SLUG"
    echo "Languages: $DETECTED_LANGUAGES"
    echo "PRP File: $PRP_FILE"
    echo "Workspace: workspace/$PROJECT_SLUG/"
    echo
    
    echo "=== SUB-AGENT DEPLOYMENT ==="
    echo "Deploy the following Sub-Agent with this exact prompt:"
    echo
    echo "---BEGIN SUB-AGENT PROMPT---"
    
    # Generate focused micro-prompt for initial content generation
    build_initial_content_prompt "$PROJECT_NAME" "$PROJECT_SLUG" "$COMBINED_CONTEXT"
    
    echo
    echo "---END SUB-AGENT PROMPT---"
    echo
    echo "=== ORCHESTRATOR SUMMARY ==="
    echo "✓ Context extracted and analyzed"
    echo "✓ Base PRP template created with placeholders replaced"
    echo "✓ Micro-prompt generated for Initial Content Generation Sub-Agent"
    echo "✓ Ready for Sub-Agent deployment"
    echo
    echo "The Sub-Agent will:"
    echo "- Read the base PRP template"
    echo "- Generate Goal, Why, What, and Success Criteria based on project context"
    echo "- Replace remaining placeholders with workspace/$PROJECT_SLUG/ paths"
    echo "- Prepare the PRP for the next stage (codebase analysis)"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi