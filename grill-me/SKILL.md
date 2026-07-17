---
name: grill-me
description: Stress-test a plan, design, architecture, or proposal by interviewing the user one question at a time until key decisions, tradeoffs, assumptions, and risks are resolved. Use when the user asks to be grilled, wants a plan challenged, or needs design review through pointed questioning.
---

Interview the user about the plan or design until there is a shared understanding of the important decisions, dependencies, constraints, and risks.

Ask one question at a time.

For each question:
- Ask the highest-leverage unresolved question.
- Prefer structured choice collection when available. If the `request_user_input` tool is available in the current mode, use it for questions that naturally fit 2-3 mutually exclusive options.
- When using `request_user_input`, provide 2-3 concrete options, put the recommended option first, and keep the option labels short and specific.
- If `request_user_input` is not available, present the question in plain text with explicit labeled choices such as `A`, `B`, and `C`, plus a recommended option.
- Provide a recommended answer or the strongest default option.
- Briefly explain why that answer is the current best choice.

When a question does not fit a clean multiple-choice format, ask it in plain text even if structured input is available.

If a question can be answered by exploring the codebase or available artifacts, inspect them first instead of asking the user.

Keep drilling into unresolved branches of the decision tree, but do not ask repetitive or low-value questions.

When running in Plan mode:
- Treat the interview as PRD discovery for an implementation-ready plan.
- When the major assumptions, interfaces, tradeoffs, failure modes, and open decisions are clear, produce exactly one `<proposed_plan>` block.
- Format the `<proposed_plan>` content as a PRD-style plan that is decision complete for implementation.
- Structure the PRD-style plan with:
  - A clear title
  - Summary or problem statement
  - Goals and success criteria
  - Key requirements or expected behavior
  - Constraints and assumptions
  - Test and acceptance scenarios
- After the `<proposed_plan>` block, explicitly ask the user whether they want to save it to a local Markdown file.
- If the user wants to save it, suggest a default filename in the current working directory such as `prd-<slug>.md`, unless they specify a different path.
- Do not write the file while still in Plan mode; defer any file creation to a follow-up execution turn.

When not running in Plan mode:
- Stop when the major assumptions, interfaces, tradeoffs, failure modes, and open decisions are clear, then summarize:
  - What was decided
  - What remains open
  - The main risks or follow-up work
