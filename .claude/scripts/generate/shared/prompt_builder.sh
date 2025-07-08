#!/bin/bash

# prompt_builder.sh
# Purpose: Build focused micro-prompts for Sub-Agents
# Philosophy: Create lean, task-specific prompts that let LLMs generate content

# Source the context gatherer to access extracted context
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/context_gatherer.sh"

# Function to build initial content generation prompt
build_initial_content_prompt() {
    local project_name="$1"
    local project_slug="$2"
    local project_context="$3"
    
    cat << EOF
# Initial Content Generation Sub-Agent

## Your Mission
You are the Initial Content Generation Sub-Agent. Your job is to populate the base PRP template with initial content based on project context.

## Context
**Project Name:** $project_name
**Project Slug:** $project_slug
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Project Context
$project_context

## Your Tasks
1. **Read the base PRP template** at PRPs/PRP_$project_name.md
2. **Generate Goal section** - Clear statement of what needs to be built
3. **Generate Why section** - Business value and user problem this solves
4. **Generate What section** - User-visible behavior and requirements
5. **Generate Success Criteria** - 3-5 specific, measurable outcomes
6. **Replace all placeholders** with workspace/$project_slug/
7. **Use MultiEdit tool** to update the PRP file

## Important Guidelines
- Generate content based on the project context provided
- Use workspace/$project_slug/ for all file paths
- Keep content focused and actionable
- Don't hallucinate - base everything on the provided context
- Make success criteria specific and measurable

When complete, output: "run: bash .claude/scripts/generate/analyze-codebase.sh"
EOF
}

# Function to build codebase analysis prompt
build_codebase_analysis_prompt() {
    local project_name="$1"
    local project_slug="$2"
    local project_files="$3"
    
    cat << EOF
# Codebase Analysis Sub-Agent

## Your Mission
Find existing code patterns and enhance the PRP with specific examples from the current codebase.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Current Codebase Structure
$project_files

## Your Tasks
1. **Scan the codebase** for existing patterns, classes, functions
2. **Identify architectural decisions** already made
3. **Find naming conventions** and code organization patterns
4. **Enhance the PRP** by adding specific examples to the "Known Gotchas & Library Quirks" section
5. **Update file references** to use workspace/$project_slug/ prefix

## Focus Areas
- Look for existing class/function patterns that should be followed
- Find configuration management approaches
- Identify testing patterns and structures
- Note any framework-specific patterns or conventions
- Document any critical setup or initialization patterns

## Output Requirements
Add specific code examples and patterns to the PRP's "Known Gotchas & Library Quirks" section.
Use this format for code examples:
\`\`\`python
# CRITICAL: Brief description of the pattern/gotcha
# Example from existing codebase
\`\`\`

When complete, output: "run: bash .claude/scripts/generate/research-external.sh"
EOF
}

# Function to build external research prompt
build_external_research_prompt() {
    local project_name="$1"
    local project_slug="$2"
    local project_context="$3"
    
    cat << EOF
# External Research Sub-Agent

## Your Mission
Research relevant external resources and enhance the PRP with technical references.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Project Context for Research
$project_context

## Your Tasks
1. **Research relevant technologies** mentioned in the project context
2. **Find official documentation** for key libraries/frameworks
3. **Identify best practices** and common pitfalls
4. **Enhance the PRP** by adding to the "Documentation & References" section
5. **Format as YAML** with url and why fields

## Research Focus
Based on the project context, research:
- Core technologies and frameworks mentioned
- Official documentation and best practices
- Common gotchas and performance considerations
- Testing and validation approaches
- Security considerations if applicable

## Output Format
Add entries to the Documentation & References section in this format:
\`\`\`yaml
- url: https://example.com/official-docs
  why: Describes the core API methods we must integrate with
  
- url: https://example.com/best-practices
  why: Performance optimization guide for the specific technology
\`\`\`

## Important Guidelines
- Focus on official documentation and authoritative sources
- Prioritize recent/current information
- Include both technical documentation and best practices
- Explain why each resource is relevant to the project

When complete, output: "run: bash .claude/scripts/generate/compile-context.sh"
EOF
}

# Function to build context compilation prompt
build_context_compilation_prompt() {
    local project_name="$1"
    local project_slug="$2"
    
    cat << EOF
# Context Compilation Sub-Agent

## Your Mission
Synthesize all research findings and codebase analysis into integrated implementation context.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Your Tasks
1. **Read the enhanced PRP** - Review all sections enhanced by previous Sub-Agents
2. **Synthesize findings** - Combine insights from codebase analysis and external research
3. **Identify integration points** - How new features connect to existing code
4. **Create coherent narrative** - Ensure all sections work together
5. **Prepare for blueprint design** - Set up foundation for detailed implementation

## Synthesis Areas
- **Integration Strategy**: How new components fit with existing architecture
- **Technical Constraints**: Limitations and requirements from research
- **Implementation Dependencies**: What must be built in what order
- **Validation Approach**: How to verify success at each step

## Output Requirements
Add new sections or enhance existing ones to create a coherent implementation story.
Focus on practical guidance for developers.

When complete, output: "run: bash .claude/scripts/generate/design-blueprint.sh"
EOF
}

# Function to build blueprint design prompt
build_blueprint_design_prompt() {
    local project_name="$1"
    local project_slug="$2"
    
    cat << EOF
# Blueprint Design Sub-Agent

## Your Mission
Create detailed implementation blueprint with specific tasks and code structures.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Your Tasks
1. **Create detailed task breakdown** - Specific, ordered implementation steps
2. **Design data models** - Code structures needed for the implementation
3. **Define integration points** - How components connect
4. **Specify file structure** - Complete workspace/$project_slug/ tree
5. **Add implementation guidance** - Specific patterns and approaches

## Blueprint Components
- **Data Models & Structure**: Code for classes, interfaces, data structures
- **Task Breakdown**: Ordered list with CREATE/MODIFY actions and specific file paths
- **Integration Points**: Configuration, database, API connections
- **File Structure**: Complete directory tree with explanations

## Output Format
Populate the "Implementation Blueprint" section with:
\`\`\`yaml
- task: 1
  action: CREATE
  path: workspace/$project_slug/src/feature.py
  details:
    - Specific implementation requirements
    - Patterns to follow from existing codebase
\`\`\`

When complete, output: "run: bash .claude/scripts/generate/create-validation.sh"
EOF
}

# Function to build validation strategy prompt
build_validation_strategy_prompt() {
    local project_name="$1"
    local project_slug="$2"
    local detected_languages="$3"
    
    cat << EOF
# Validation Strategy Sub-Agent

## Your Mission
Design comprehensive validation approach for the implementation.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/
**Languages:** $detected_languages

## Your Tasks
1. **Design validation levels** - Syntax, unit tests, integration tests
2. **Create specific test cases** - Based on the implementation requirements
3. **Define validation commands** - Executable commands for each level
4. **Set success criteria** - Clear pass/fail criteria for each level

## Validation Levels
- **Level 1**: Syntax & Style (linting, formatting, type checking)
- **Level 2**: Unit Tests (individual component testing)
- **Level 3**: Integration Tests (full system testing)

## Output Requirements
Populate the "Validation Loop" section with:
- Specific commands to run for each level
- Test cases with expected outcomes
- Clear success/failure criteria
- Commands should use workspace/$project_slug/ paths

When complete, output: "run: bash .claude/scripts/generate/finalize-prp.sh"
EOF
}

# Function to build final QA prompt
build_final_qa_prompt() {
    local project_name="$1"
    local project_slug="$2"
    
    cat << EOF
# Final QA Sub-Agent

## Your Mission
Perform final quality assurance and ensure the PRP is implementation-ready.

## Context
**Project:** $project_name
**PRP File:** PRPs/PRP_$project_name.md
**Workspace:** workspace/$project_slug/

## Your Tasks
1. **Review complete PRP** - Ensure all sections are coherent and complete
2. **Validate workspace references** - All paths use workspace/$project_slug/
3. **Check implementation readiness** - Can a developer follow this to completion?
4. **Add final touches** - Executive summary, implementation notes
5. **Assess confidence level** - Rate implementation readiness (1-10)

## Quality Checklist
- [ ] All sections are complete and coherent
- [ ] Workspace paths are consistent throughout
- [ ] Implementation tasks are specific and actionable
- [ ] Validation procedures are executable
- [ ] Success criteria are measurable
- [ ] Integration points are clear

## Final Output
Add an executive summary and provide a confidence score for implementation readiness.
Report any remaining gaps or recommendations.

When complete, output: "PRP generation complete. Implementation readiness: X/10"
EOF
}

# Function to get appropriate prompt based on stage
get_prompt_for_stage() {
    local stage="$1"
    local project_name="$2"
    local project_slug="$3"
    local context="$4"
    
    case "$stage" in
        "initial")
            build_initial_content_prompt "$project_name" "$project_slug" "$context"
            ;;
        "codebase")
            build_codebase_analysis_prompt "$project_name" "$project_slug" "$context"
            ;;
        "research")
            build_external_research_prompt "$project_name" "$project_slug" "$context"
            ;;
        "compile")
            build_context_compilation_prompt "$project_name" "$project_slug"
            ;;
        "blueprint")
            build_blueprint_design_prompt "$project_name" "$project_slug"
            ;;
        "validation")
            build_validation_strategy_prompt "$project_name" "$project_slug" "$context"
            ;;
        "finalize")
            build_final_qa_prompt "$project_name" "$project_slug"
            ;;
        *)
            echo "❌ ERROR: Unknown stage '$stage'"
            echo "Available stages: initial, codebase, research, compile, blueprint, validation, finalize"
            return 1
            ;;
    esac
}

# Main function for testing
main() {
    echo "=== Micro-Prompt Builder ==="
    echo "This script provides functions to build focused prompts for Sub-Agents."
    echo "Usage: source this script and call get_prompt_for_stage <stage> <project_name> <project_slug> <context>"
    echo ""
    echo "Available stages:"
    echo "  initial    - Initial content generation"
    echo "  codebase   - Codebase analysis"
    echo "  research   - External research"
    echo "  compile    - Context compilation"
    echo "  blueprint  - Blueprint design"
    echo "  validation - Validation strategy"
    echo "  finalize   - Final QA"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi