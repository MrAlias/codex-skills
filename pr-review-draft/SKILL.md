---
name: pr-review-draft
description: Review a GitHub pull request from source artifacts or turn existing findings into a polished review. Use when Codex should inspect a PR diff against its base branch, check CI status and prior GitHub feedback, and produce a Senior Staff Engineer-style review with a concise summary plus specific actionable findings by severity. Also use when Codex should draft or post a GitHub review from completed findings. For drafts, emit the exact valid JSON payload intended for the posting tool, with verified diff line ranges, correctly scoped GitHub suggestion blocks, the user's maintainer voice, and self-contained comments.
---

# PR Review Draft

Use this skill for two related workflows:

1. Review a PR from source.
Start from a PR number, PR URL, or the current branch. Inspect the checked-out diff against the base branch, check CI status, and read prior GitHub review feedback before generating findings.

2. Turn existing findings into a postable review.
Start from a pasted review dump or selected findings. Compare them with prior PR discussion, then draft or post concise top-level and inline review comments.

## Defaults

When the user says something short like `Use pr-review-draft to review PR #1867`, default to:
- compare against the PR base branch
- use a Senior Staff Engineer review voice
- check CI status
- check prior GitHub feedback
- focus on correctness, architecture, security/performance, test coverage, and documentation/naming

Treat `show me the draft`, `draft the review`, and similar requests after findings are concluded as requests for the exact postable JSON payload. A request for a draft is not authorization to post it.

Default to reviewing the PR from source artifacts unless the user explicitly provides completed findings and asks you to reformat, deduplicate, or post them.

Do not assume the review output has already been provided.

Do not ask follow-up questions just to confirm these defaults. Ask only when something is genuinely ambiguous or the user explicitly asks for customization.

## Review From Source

When the user asks for a review:

1. Identify the target PR and base branch.
Use the current branch if needed. Use the PR base branch by default.

2. Inspect the checked-out diff against the base branch.
Read the changed files and focus on behavior, not just style.

3. Check GitHub context.
Review:
- CI status
- prior review comments
- issue comments
- author replies

4. Evaluate the areas the user requested.
Typical axes:
- logic and correctness
- architecture and maintainability
- security and performance
- test coverage
- documentation and naming

5. Produce findings first.
Order by severity. Each finding should explain:
- what is wrong
- when it breaks
- why it matters

6. Keep the summary brief.
Summarize the change only after the findings, unless the user explicitly asked for a longer overview.

## Draft Or Post Review Comments

When the user wants the findings turned into GitHub comments:

1. Refresh the PR before drafting.
Read the latest head SHA, current code, and current patch. Do not draft inline locations from a stale review dump or finding summary.

2. Check prior PR discussion before calling findings new.
Distinguish:
- exact duplicate already posted
- same theme raised earlier but different concrete failure mode
- genuinely new finding

3. Match the user's review voice.
Use explicit style guidance and available examples of the user's own review comments to learn phrasing, cadence, and project terminology. When access permits, identify the authenticated user's GitHub login and sample three to five recent, substantive reviews from the same repository or community. Prefer examples supplied in the current task, then same-repository reviews, then closely related repositories. Ignore bots, copied boilerplate, and unusually context-specific comments. Transfer style only; never transfer unrelated content or private context.

4. Read [GitHub review payloads and suggestions](references/github-review-payloads.md) completely.
Also inspect the schema or documentation for the posting tool selected for this review. The active tool schema is authoritative when it differs from the REST examples in the reference.

5. Make the top-level review body an overall engineering judgment, not a review inventory.
In one or two sentences, synthesize the most important cross-cutting concerns without repeating inline comments. Keep the merge posture clear from the review action and body together. Avoid a generic declaration that issues must be resolved before merge when the findings and review context already establish that; retain explicit blocking language when merge intent would otherwise be ambiguous. Do not count findings or list severity totals. Do not report CI status as bookkeeping unless it materially changes the overall assessment.
Prefer: `I found a few gaps in the live-check coverage, along with an enum migration issue that appears to be keeping the suite red.`
Reject: `The live-check plumbing still permits telemetry loss to escape validation. These issues need to be resolved before merge.`

6. Select the GitHub review action deliberately; read [Review action selection](#review-action-selection) before constructing a draft.

7. Put specific feedback inline on the relevant lines.
Each inline comment should:
- identify the behavioral risk or regression
- explain the scenario where it matters
- point to existing repository logic or patterns when reuse is preferable
- include an apply-ready GitHub suggestion block when a concrete, local correction is clear and useful

8. Verify every inline location against the refreshed patch.
Confirm the repository-relative path, first and last line, diff side, suggestion replacement span, and latest head SHA. Never guess an anchor or reuse obsolete line numbers.

9. Show or post the review.
For a draft, follow the exact JSON contract below. If the user asks to post, submit one review with all inline comments attached. If the head SHA or any payload field changes after the user approves a draft, show the replacement JSON instead of silently posting a different payload.

## Exact Draft Contract

When the user asks to see the draft:

- Select the actual posting tool or endpoint first.
- Return one fenced `json` block containing the exact argument object or request body that will be sent. Use the active tool's real field names and nesting; do not translate it into a generic review schema.
- Keep the JSON parse-valid and complete. Include every field that will be sent, preserve every comment body byte-for-byte, and omit fields that will not be sent. Do not use placeholders, ellipses, comments, or trailing commas.
- Encode Markdown and suggestion blocks inside JSON strings with the required escapes, including `\n` and `\t`.
- Do not present a separate prose or Markdown version of the review that could drift from the payload.
- Use the displayed object unchanged when posting. Re-render and re-present it if validation requires any change.

If repository or PR identifiers are arguments to the selected tool, include them in the JSON. If they are path parameters outside a REST request body, identify the endpoint immediately before the JSON block, then show the exact request body.

Before showing the draft, parse the JSON with a real JSON parser and verify it against the selected tool schema.

## Review Action Selection

`COMMENT` and `REQUEST_CHANGES` are GitHub workflow actions, not severity
labels. Keep the action decision separate from whether an inline finding is
important or must be addressed before merge.

In the OpenTelemetry repositories this user maintains, a `COMMENT` review is
normally used for actionable feedback—including correctness defects, failed CI,
and items that must be resolved before merge—when it adds to an existing merge
block or records another review pass. A prior `REQUEST_CHANGES` review remains
the formal merge posture until its blockers are resolved and the reviewer
changes that posture. Do not use another `REQUEST_CHANGES` merely because the
new comment is important, the PR is still not ready, or the top-level body says
an item must be addressed.

Default to `COMMENT`. Select `REQUEST_CHANGES` only when all of the following
are true:

- the user explicitly requests it, or the evidence supports establishing a new
  formal, merge-blocking review decision;
- the finding is a concrete unresolved blocker for the current head, rather
  than an optional improvement, a question, an uncertain concern, or a request
  for a broader alternative;
- no earlier `REQUEST_CHANGES` review by this reviewer still covers unresolved
  blockers on the PR; and
- submitting a new formal block is appropriate to the project's review
  lifecycle, rather than simply adding feedback to the existing review state.

Before choosing the action, inspect this reviewer's prior reviews, their states,
author replies, and the current head. Treat a prior request as still standing
when its concrete blockers have not been resolved in the current code. Its age,
a newer commit, or additional findings do not by themselves justify another
request-changes event. Use `COMMENT` for follow-up findings while that request
stands. If the state cannot be determined, use `COMMENT` unless the user
explicitly directs `REQUEST_CHANGES`.

The top-level body must remain honest about merge readiness regardless of the
chosen action. A `COMMENT` may say that a concrete issue needs resolution
before merge; it must not pretend the feedback is optional. Conversely, do not
claim a new formal block in prose when the review action is `COMMENT`; describe
the code and merge condition directly.

## Comment Style

Write as the user: a maintainer and respected member of the community reviewing a peer's contribution. Prefer the user's demonstrated phrasing and terminology over a generic house style.

Keep the voice:
- direct
- specific
- confident
- concise
- critical where needed
- collegial, constructive, and actionable

Avoid:
- a generic assistant persona, including polished-but-impersonal prose
- sycophantic, conciliatory, or apologetic language
- excessive compliments or praise used to soften a finding
- inflated praise
- vague statements
- repeating the same finding in the top-level and inline comments
- long design essays when a short correction is enough

Do not invent familiarity, community history, or opinions the user has not demonstrated. If no writing samples are available, use a straightforward maintainer voice without performative warmth.

Frame findings as shared engineering problems, not indictments. Lead with a neutral observation and its concrete consequence. When several fixes could work, prefer a collaborative request such as `Could we…?` over a stacked sequence of imperatives. Avoid prosecutorial phrasing and unnecessary statements that an issue `must be resolved before merge` when the finding and review context already make that clear.

Calibrate confidence to the evidence. Use `appears`, `may`, or `can` only when uncertainty is real; do not hedge established behavior. Do not mechanically turn every comment into a question, add pleasantries, or soften genuine blockers. Retain explicit blocking language whenever merge intent would otherwise be ambiguous.

Before:
> This baseline is captured after the tests. Capture it before tests start and treat scrape failures as fatal.

After:
> This baseline is captured only after the tests, so earlier failures are already included and may escape the delta check. Could we capture it before tests start? I also think a scrape failure should make the report untrustworthy.

### Human Voice Guardrails

The goal is not to simulate informal human writing or to evade AI detection. Do not add typos, slang, jokes, personal anecdotes, or disagreement merely to sound human. Make the review sound like a real maintainer by making each sentence earn its place: express a specific technical judgment, grounded in this repository and this patch.

Before rendering a comment, remove these common assistant habits:

- **Ritualized openings and closings.** Do not start every comment with `Great work`, `Thanks for`, `I appreciate`, `It looks like`, `It is worth noting`, or `I hope this helps`. Praise is appropriate only when it names a concrete decision and its benefit, and it should usually be a separate, non-blocking comment.
- **Formulaic transitions and elevated filler.** Prefer plain engineering language to stock connectors or grand framing such as `moreover`, `furthermore`, `additionally`, `in conclusion`, `delve`, `tapestry`, `testament`, `crucial`, `robust`, `seamless`, `landscape`, or `it is important to note`. Do not write `not only … but also …` when two direct sentences are clearer.
- **Polished vagueness.** Replace `this could lead to issues`, `this may impact reliability`, `this is suboptimal`, or `this won't work` with the concrete input/state, observed behavior, and impact. Omit a concern when that chain cannot be supported from the patch or repository.
- **Template-shaped prose.** Do not make every comment follow the same opener, sentence count, transition, or closing request. Vary syntax naturally while preserving clarity; short direct comments are often best. Never add a recap paragraph merely to make a comment feel complete.
- **Performative agreement and false certainty.** Do not agree with the PR's premise to soften a disagreement. Do not call a change `correct`, `safe`, or `ready` without evidence. When repository context is missing, ask one focused question and state the assumption being checked instead of wrapping an unsupported claim in hedging.
- **Over-explaining the obvious.** Do not narrate what the changed code visibly does, restate the diff, teach a general concept the author clearly knows, or prescribe a full design when identifying the constraint is enough. Add the non-obvious consequence, existing precedent, or decision the author needs to act.
- **Mechanical politeness.** Let collegiality come from discussing the code as a shared problem. Do not pad comments with apologies, repeated `please`, praise, or formulaic questions; keep blockers unmistakable when the review context does not already establish them.

Use project-native severity labels (`blocking`, `nit`, `question`, `optional`, or the repository's established equivalent) only when they clarify merge intent. Do not manufacture a label for every comment.

As a final voice check, ask:

1. Would a maintainer who read the patch write this exact technical point, or could it fit almost any PR?
2. Does it name the triggering condition and consequence instead of offering generic concern or encouragement?
3. Is every courtesy phrase, transition, and sentence necessary?
4. Does its confidence match the evidence? If not, should it be a focused question or be omitted?

These guardrails reflect observed AI-text cues such as unusually formal/flowery vocabulary, complex and repetitive sentence patterns, and tidy conclusory structure ([ACL 2025 study](https://aclanthology.org/2025.acl-long.267.pdf)). They also preserve what practitioners value in review comments: added information beyond the code, adequacy, and concision—typically two or three lines ([ICSE 2022 study](https://xin-xia.github.io/publication/icse224.pdf)).

## Self-Contained Review

Make the submitted review understandable from the PR and repository alone:

- State the concrete problem, triggering scenario, impact, and requested direction in the review itself.
- Do not mention the drafting process, internal analysis, the user's prompt, private conversation, or invisible context.
- Avoid references such as `as we discussed`, `from the earlier review`, or `the issue I mentioned` unless the referenced text is part of the same visible GitHub thread and the comment still restates the necessary context.
- Restate any essential repository or prior-discussion context instead of requiring the author to chase it.
- Use links and citations as supporting evidence, not as a substitute for the explanation.

## Review Output Shape

For a source review, prefer this structure:

1. Findings by severity.
2. Open questions or assumptions, if any.
3. Short summary of the overall change.

For a requested draft, replace this human-readable structure with the exact JSON payload contract above. For posted review comments, keep the review body brief if the important detail is already inline.

## Invocation Patterns

Support these short forms without extra clarification when the defaults are sufficient:

```text
Use pr-review-draft to review PR #1867
Use pr-review-draft to review PR #1867 against main
Use pr-review-draft to review PR #1867 without checking CI
Use pr-review-draft to review PR #1867 as a security-focused reviewer
Use pr-review-draft to turn these findings into inline PR comments
```

## Inline Comment Construction

Build each inline comment from the evidence, not from a canned fill-in-the-blank template. A useful compact shape is:

````md
When <concrete condition>, <this code> <observable behavior>. That leaves <impact>.

Could we <requested direction>? <Repository helper/pattern> already handles <relevant case>.

```suggestion
<complete, apply-ready replacement for the precisely selected line range>
```
````

Use only the parts that add information. For example, a self-evident local correction may need one sentence and a suggestion; a design concern may need the condition, consequence, and a question but no prescriptive solution. Omit the suggestion block when the exact replacement is not clearly correct in context. Never put illustrative or incomplete code in an apply-ready suggestion.

## Deduplication Guidance

When asked whether findings are new:
- say "not new" only if the same concrete issue was already posted
- say "same theme, new formulation" when earlier comments touched the area but did not state the same failure mode
- say "new" when neither the exact bug nor the concrete failure mode appears in prior comments

When asked whether earlier comments were addressed:
- separate "acknowledged by the author" from "actually resolved"
- use both author replies and the current code state

## GitHub Tools

When GitHub connector tools are available, prefer them for:
- locating the PR for the current branch
- reading PR metadata, comments, and reviews
- checking CI status
- fetching file patches for inline placement
- posting the final review

Use repository code and local diff context as the source of truth for whether a prior concern is actually resolved.
