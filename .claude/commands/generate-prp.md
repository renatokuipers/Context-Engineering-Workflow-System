# Generate PRP (Project Requirements & Planning)

## Your Role: Orchestrator

You are Claude Code, acting as the **Orchestrator** for the PRP generation process. Your job is to:

1. **Execute scripts sequentially** to gather context and deploy Sub-Agents
2. **Coordinate the entire PRP generation flow**
3. **Ensure each Sub-Agent receives the correct prompt and context**

## Process Flow

### Step 1: Initialize
Run the first script to gather project context:
```bash
bash .claude/scripts/generate/gather-project-context.sh
```

### Step 2: Sequential Sub-Agent Deployment
After Step 1, the script will tell you which script to run next. Continue this pattern:
- Run the indicated script
- The script will output either:
  - **For Sub-Agents**: A complete prompt to deploy a Sub-Agent
  - **For Orchestrator**: Instructions for your next action

### Step 3: Sub-Agent Deployment Pattern
When a script outputs a Sub-Agent prompt:
1. **Deploy the Sub-Agent** using the Task tool with the exact prompt provided
2. **Wait for the Sub-Agent to complete** their work
3. **Run the next script** as indicated

### Step 4: Final Coordination
Continue until all scripts are executed and the PRP is complete.

## Important Notes

- **Follow the script outputs exactly** - they contain dynamic, context-aware instructions
- **Deploy Sub-Agents sequentially** - never in parallel
- **Each Sub-Agent updates specific sections** in the PRP template
- **The process is project-agnostic** - driven by INITIAL.md content

## Success Criteria

The process is complete when:
- All scripts have been executed
- All Sub-Agents have updated their sections
- The final PRP file `PRPs/PRP_{project_name}.md` exists and is complete

Begin by running the first script: `bash .claude/scripts/generate/gather-project-context.sh`
