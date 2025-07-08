# Context Engineering Workflow System

A comprehensive, two-part workflow system for engineering context and orchestrating AI agents to build complex software projects from the ground up. This system demonstrates an advanced, **Context-Engineered** approach that is significantly more powerful and reliable than traditional prompt engineering.

> **This isn't just about asking an AI to code; it's about building an automated factory that *uses* AI to code.**

## 🚀 Quick Start

```bash
# 1. Clone this template
git clone https://github.com/your-repo/context-engineering-workflow.git
cd context-engineering-workflow

# 2. Define your project's vision
#    - Edit INITIAL.md with your high-level feature requirements.
#    - (Optional) Add detailed design documents, diagrams, or notes to the docs/ folder.

# 3. Generate the master blueprint (PRP)
#    In Claude Code, run the Part 1 workflow:
/generate-prp

# 4. Execute the blueprint to build the project
#    Once the PRP is generated, run the Part 2 workflow and watch the magic happen:
/execute-prp PRPs/PRP_your-project-name.md
```

## 📚 Table of Contents

- [What is this System?](#what-is-this-system)
- [How It Works: A Two-Part System](#how-it-works-a-two-part-system)
- [Template Structure](#template-structure)
- [Step-by-Step Guide](#step-by-step-guide)
- [Writing Your `INITIAL.md`](#writing-your-initialmd)
- [Best Practices for Success](#best-practices-for-success)

## What is this System?

This project isn't just a set of prompts; it's a complete, automated system that separates **planning** from **execution**. It uses a series of orchestrated shell scripts and specialized AI sub-agents to first create a deeply researched and validated project plan, and then execute that plan with precision.

### Prompt Engineering vs. This System

**Traditional Prompt Engineering:**
- Focuses on crafting the perfect, single request.
- Is brittle and struggles with complex, multi-step tasks.
- Like giving a construction worker a verbal instruction and hoping for the best.

**This Context-Engineered Workflow:**
- A complete, stateful system that manages a project from idea to code.
- Uses context (your `INITIAL.md` and `docs/`) to first **generate a master blueprint (the PRP)**.
- Then uses that blueprint to **deploy a team of specialized AI agents** to build each part of the project sequentially in a **fully autonomous loop**.
- Like having an AI architect design a skyscraper and an AI general contractor that autonomously manages the entire build process, from foundation to finishings.

### Why This Approach is Superior

1.  **Reduces AI Failure**: By breaking the problem down, we prevent context overload and hallucination.
2.  **Enforces Quality & Consistency**: The workflow validates each agent's work against project rules before moving on.
3.  **Enables True Complexity**: The system can build large, multi-file applications because it manages dependencies between components autonomously.
4.  **Creates a Self-Correcting Loop**: The workflow includes validation steps that can identify issues, and future versions can even trigger self-correction.

## How It Works: A Two-Part System

This workflow is divided into two main slash commands, each running a sophisticated orchestration of scripts.

### Part 1: `/generate-prp` (The Architect)

This command reads your initial idea and builds the master blueprint.
1.  **Context Gathering**: It reads your `INITIAL.md` and everything in `docs/`.
2.  **External Research**: It deploys a research agent to find best practices and validate the technologies you mentioned.
3.  **Blueprint Design**: It creates a detailed implementation plan, including a file structure and a task breakdown.
4.  **Validation Plan**: It designs the tests that will be needed to verify the final code.
5.  **Final Output**: It produces a comprehensive **Project Requirements & Planning (`PRP`)** document in the `PRPs/` folder.

### Part 2: `/execute-prp` (The Autonomous Factory)

This command takes the generated PRP and builds the software from start to finish.
1.  **Workspace Setup**: It reads the PRP and creates the entire directory structure for your new project.
2.  **Automated Task Planning**: The Orchestrator AI analyzes the PRP and automatically generates a `workspace/workflow/tasks.md` file, creating a concrete build plan.
3.  **Autonomous Build Loop**: The system initiates a self-sustaining loop:
    - It deploys the first agent for Task 1.
    - When Task 1 is complete, the system automatically updates its state (`progress.md`, `dependencies.md`).
    - It performs a quality check on the new code.
    - It immediately deploys the agent for Task 2, providing it with the context from Task 1.
    - This cycle repeats without human intervention until the final task is complete.

## Template Structure

```
.
├── .claude/
│   ├── commands/
│   │   ├── generate-prp.md       # Command to trigger the planning phase
│   │   └── execute-prp.md        # Command to trigger the autonomous build phase
│   └── scripts/
│       ├── generate/             # Scripts for the `/generate-prp` workflow
│       └── execute/              # Scripts for the `/execute-prp` workflow
├── PRPs/
│   └── templates/
│       └── prp_base.md           # The base template for all generated PRPs
├── docs/                         # (Optional) Add your detailed design docs here
├── CLAUDE.md                     # Global rules for all AI agents
├── INITIAL.md                    # Your high-level project definition starts here
└── README.md                     # This file
```

## Step-by-Step Guide

### 1. Define Global Rules (`CLAUDE.md`)

This file contains project-wide rules that every AI agent will follow. The provided template is robust, covering coding standards, performance requirements, and error handling. You can customize it to match your own conventions.

### 2. Write Your Project Vision (`INITIAL.md`)

This is your primary input. Edit `INITIAL.md` to describe the software you want to build. Be as detailed or as high-level as you want. The more context you provide here (and in `docs/`), the better the final plan will be.

*(See the section below for tips on writing a great `INITIAL.md`.)*

### 3. Generate the Master Blueprint (`PRP`)

This step is fully automated. In Claude Code, run:
```bash
/generate-prp
```
The system will take over, running its research and planning agents. When it's finished, you will find a new `PRPs/PRP_your-project-name.md` file. **Review this file.** It is the complete plan for your project.

### 4. Unleash the Autonomous Factory

This is the final step. Trigger the autonomous build process and watch your project come to life.
```bash
/execute-prp PRPs/PRP_your-project-name.md
```
From this point on, the system is **fully autonomous**. It will:
1.  Set up the entire workspace.
2.  Have the Orchestrator AI analyze the PRP and create the `tasks.md` build plan.
3.  Begin the build loop, deploying agents sequentially for each task.
4.  Update its internal state and validate the work after each step.
5.  Continue until all tasks from the `tasks.md` file are complete and the project is built.

You can monitor the progress by watching the `workspace/workflow/progress.md` and `workspace/workflow/dependencies.md` files update in real-time.

## Writing Your `INITIAL.md`

Your `INITIAL.md` is the seed for the entire process. A good seed grows a strong tree.

### Key Sections Explained

*   **`## FEATURE:`**: The "what." Describe the core functionality. Be specific.
    *   ❌ "A game automation tool."
    *   ✅ "A GUI-driven game automation studio for Windows/Linux using Python, featuring a no-code visual editor for creating AI agents."
*   **`## EXAMPLES:`**: The "how." Explain data flows or desired component interactions. You don't need to provide code here; describe the behavior.
    *   ✅ "`node_canvas.ui -> visual_agent_logic.json`: A user drags a `Find Object` node..."
*   **`## DOCUMENTATION:`**: The "knowledge." Link to any relevant external APIs, libraries, or design patterns you want the system to use.
*   **`## OTHER CONSIDERATIONS:`**: The "gotchas." List hard requirements like performance targets, technical challenges, and platform specifics.

> **Pro Tip:** Use an AI to help you write your `INITIAL.md`! You can give it the template from this repository's `INITIAL.md` and your high-level idea, and ask it to flesh out the details in the correct format.

## Best Practices for Success

1.  **Front-Load Your Context**: The more detail you put into `INITIAL.md` and `docs/`, the more accurate and robust the final `PRP` will be. Garbage in, garbage out. Quality in, quality out.
2.  **Trust the Process**: The system is designed to be sequential and autonomous. Once you kick off `/execute-prp`, let it run. Its internal state management and validation loops are designed to handle the complexity.
3.  **Review the Blueprint**: Before starting the `/execute-prp` workflow, take the time to read the generated `PRP`. It's your chance to catch any architectural misunderstandings before the autonomous build begins.
4.  **Monitor the Build**: Keep an eye on the `progress.md` and `dependencies.md` files in the `workspace/workflow` directory to see the project come to life in real-time.
5.  **Customize `CLAUDE.md`**: Fine-tune the global rules to enforce your specific coding standards, making the output feel like it was written by yourself.

## Resources

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Context Engineering Best Practices](https://www.philschmid.de/context-engineering)
