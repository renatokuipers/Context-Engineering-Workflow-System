#!/bin/bash

# check-file-size.sh
# Purpose: A self-validation tool for Sub-Agents to check their own created files against the 500-line limit.
# Philosophy: Empower agents to self-correct before handing off work.

# --- Validation and Usage ---
if [ "$#" -eq 0 ]; then
    echo "✅ SUCCESS: No files provided to check. Compliance check passed by default."
    exit 0
fi

echo "📏 Checking file size compliance (500 line limit) for ${#} file(s)..."

# --- Logic ---
oversized_files=()
for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "  ⚠️  WARNING: File not found: $file. Skipping."
        continue
    fi
    
    line_count=$(wc -l < "$file")
    
    if [[ $line_count -gt 500 ]]; then
        oversized_files+=("$file:$line_count")
        echo "  ❌ $file ($line_count lines) - EXCEEDS 500-LINE LIMIT."
    else
        echo "  ✓ $file ($line_count lines) - OK."
    fi
done

# --- Output and Action ---
if [[ ${#oversized_files[@]} -gt 0 ]]; then
    echo
    echo "🛑 HALT: You have created one or more files that exceed the 500-line limit."
    echo "You must refactor them now. Follow these instructions precisely."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "REFACTORING TASK FOR YOURSELF (SUB-AGENT)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for oversized_file_info in "${oversized_files[@]}"; do
        file_path=$(echo "$oversized_file_info" | cut -d: -f1)
        line_count=$(echo "$oversized_file_info" | cut -d: -f2)

        echo
        echo "### Refactor Task: $file_path ($line_count lines)"
        echo
        echo "**Objective**: Split this file you just created into smaller, logical modules. The goal is to improve maintainability by ensuring no single file exceeds 500 lines."
        echo
        echo "#### Critical Refactoring Rules:"
        echo "1.  **Preserve Logic**: You MUST NOT add, remove, or change the existing code's logic. This is a pure refactoring task."
        echo "2.  **Logical Cohesion**: Split the code based on functionality (e.g., separate classes into different files, group related utility functions)."
        echo "3.  **Update Imports**: After creating new files, you MUST update all imports. This includes fixing imports in the newly created files and updating any other files you created in this task that were importing from the original, now-refactored file."
        echo "4.  **File Naming**: Give new files clear, descriptive names that reflect their content."
        echo
        echo "#### File Content to Refactor:"
        echo '```'
        # We add the language hint for better syntax highlighting in the prompt
        if [[ "$file_path" == *.py ]]; then echo 'python'; fi
        cat "$file_path"
        echo '```'
        echo
    done
    
    echo "#### Next Steps:"
    echo "1.  Refactor the file(s) listed above according to the rules."
    echo "2.  Run the relevant tests to ensure you have not introduced any regressions."
    echo "3.  Once the refactoring is complete and tests pass, run "check-file-size.sh" again with the NEW file paths to verify compliance."
    echo "4.  Only when this script passes for all files should you proceed to create your final summary."
    
    # Exit with an error code to signify failure and halt the agent's current plan.
    exit 1
else
    echo "✅ SUCCESS: All created files comply with the 500-line limit."
    exit 0
fi