---
name: pr-feedback-handler
description: Review all feedback on a GitHub pull request, separate valid from invalid feedback, implement the valid changes, commit the work in logical units, and report what was and was not addressed. Use when the user wants end-to-end handling of PR feedback rather than a narrow reply to one thread.
---

# PR Feedback Handler

Use this skill when the user wants Codex to work through all feedback on a pull request and carry the task through local commits.

Default outcome:

- inspect all relevant PR feedback
- classify each item
- implement valid feedback
- verify locally when feasible
- create local commits grouped by behavior area
- report what changed and what was intentionally not changed

Do not push, resolve GitHub threads, post replies, or submit reviews unless the user explicitly asks.

## Feedback Scope

Include these surfaces by default:

- unresolved and resolved review threads when they provide context
- inline review comments
- review summaries such as `COMMENT` or `REQUEST_CHANGES`
- top-level PR conversation comments

Ignore standalone CI triage unless a feedback item explicitly points at a failing check or log.

## Workflow

1. Resolve the PR.
   - Use the repo and PR number, PR URL, or current branch PR if the user did not provide all context.
   - Confirm repository scope before making GitHub calls.
2. Fetch review context.
   - Use the GitHub app tools for PR metadata, changed files, patch context, and flat comment reads.
   - Use the thread-aware `gh api graphql` path when the task depends on `reviewThreads`, `isResolved`, `isOutdated`, reply chains, or precise inline anchors.
   - If CLI auth is needed, check `gh auth status` first.
3. Build one working set of feedback.
   - Normalize comments into a single list with source, author, file or line anchor when present, and current thread status.
   - Deduplicate repeated asks across review summaries, top-level comments, and thread replies.
4. Classify each feedback item.
   - Use the categories in [references/classification.md](references/classification.md).
   - Separate valid or actionable items from invalid, duplicate, already-satisfied, informational, and ambiguous items.
5. Confirm only when needed.
   - If the user asked to address all feedback, treat that as permission to handle all clearly valid items.
   - Ask before editing only when feedback conflicts, is too ambiguous to implement safely, or would require a product decision.
6. Implement valid feedback.
   - Cluster changes by behavior area or subsystem, not by individual comment unless the changes are truly unrelated.
   - Keep each code change traceable back to one or more feedback items.
   - If the right response is explanation rather than code, do not force a code change.
7. Verify locally.
   - Run the narrowest useful tests, checks, or builds for the changed area.
   - If full verification is not possible, say what was not run and why.
8. Commit locally in logical units.
   - Group related fixes by behavior area.
   - Do not mix unrelated review items into one commit just to reduce commit count.
   - Do not rewrite or revert unrelated user changes already present in the worktree.
9. Report the result.
   - Summarize what was addressed, what was not addressed, why, what commits were created, and what verification was run.

## Commit Rules

- Prefer one commit per behavior area or subsystem.
- Collapse multiple comments into one commit when they require one coherent code change.
- Split commits when feedback touches unrelated behaviors, different subsystems, or separate risk profiles.
- Write commit messages that describe the behavior change, not the review thread.

## Write Safety

- Do not push or open a PR unless explicitly asked.
- Do not reply on GitHub, resolve threads, or submit a review unless explicitly asked.
- Do not assume flat connector comments are a complete representation of thread state.
- Do not blindly implement contradictory comments; surface the conflict first.
- Do not revert unrelated local changes.

## Feedback Communication Style

Write replies and the final report as a maintainer accounting for a concrete engineering decision, not as a generic assistant narrating a workflow. The goal is not to imitate casual human writing or evade AI detection. Do not add typos, slang, jokes, personal anecdotes, or artificial disagreement. Make each sentence earn its place with a decision, evidence, or next action.

Avoid these common assistant habits:

- **Ritualized gratitude and reassurance.** Do not open every reply with `Thanks for catching this`, `Great point`, `I appreciate the feedback`, or `You're absolutely right`. Acknowledge a reviewer only when it adds meaningful context; say exactly what the feedback exposed or changed.
- **Formulaic transitions and elevated filler.** Prefer plain engineering language to `moreover`, `furthermore`, `additionally`, `in conclusion`, `delve`, `tapestry`, `crucial`, `robust`, `seamless`, `landscape`, or `it is important to note`. Do not add a recap merely to make a reply feel complete.
- **Polished vagueness.** Replace `this could cause issues`, `this improves reliability`, `the concern has been addressed`, or `this is suboptimal` with the relevant condition, changed behavior, and impact. For an implementation, name the code or test that proves the resolution.
- **Performative agreement or false certainty.** Do not agree just to soften a disagreement, and do not call feedback `correct`, `resolved`, or `safe` without checking the current code. When the evidence is incomplete, ask one focused question or state the assumption instead of hiding uncertainty behind hedging.
- **Mechanical politeness.** Discuss the code and decision, never the reviewer or author. Do not pad a rejection with apologies, repeated `please`, or praise. A respectful, evidence-backed disagreement is more useful than a soft but ambiguous answer.
- **Process narration.** Do not tell reviewers that you "reviewed the feedback," "updated the implementation," or "completed the task" without stating what actually changed. Do not mention internal analysis, prompts, tool use, or invisible context.

For a reply to a valid item, state the concrete fix and, when useful, the verification that covers it. For an explanation-only or rejected item, state the repository evidence and the decision directly. Do not force a code change merely to give a satisfying affirmative answer.

Before posting any reply or producing the final report, check:

1. Could this sentence be pasted onto an unrelated PR? If so, replace it with patch-specific evidence or remove it.
2. Does it distinguish an author acknowledgment from a verified resolution?
3. Does it say what changed, why it matters, and—when relevant—how it was verified?
4. Does its confidence match the checked code and tests?

These guardrails address observed AI-text cues including unusually formal or flowery vocabulary, repetitive sentence patterns, and neat conclusory structure ([ACL 2025 study](https://aclanthology.org/2025.acl-long.267.pdf)). They also favor the concrete, concise, added information practitioners expect from software comments ([ICSE 2022 study](https://xin-xia.github.io/publication/icse224.pdf)).

## Output

End with a concise report using this shape:

- `Addressed`: feedback clusters that resulted in code changes
- `Not addressed`: invalid, duplicate, already-satisfied, explanation-only, or ambiguous items with a short reason
- `Commits`: local commits created and what each commit covers
- `Verification`: tests or checks run, plus anything skipped

Under each heading, lead with the concrete outcome rather than a generic status sentence. Keep the report scannable, but do not use these headings to hide missing reasoning; include the trigger and rationale for every item that was intentionally not addressed.

## Fallback

If the PR cannot be resolved cleanly, say whether the blocker is:

- missing repository scope
- missing PR identifier
- missing GitHub CLI authentication
- missing permission to inspect the repository

Then ask for the missing input instead of guessing.
