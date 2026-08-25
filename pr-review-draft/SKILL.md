---
name: pr-review-draft
description: Review a GitHub pull request from source artifacts or turn existing findings into a polished review. Use for initial or follow-up review passes, including when Codex should inspect a PR diff against its base branch, preserve continuity with prior feedback, converge on unresolved concerns, check CI status, and produce a thorough, evidence-led Senior Staff Engineer-style review with a concise summary plus specific actionable findings by severity. Also use when Codex should draft or post a GitHub review from completed findings. For drafts, emit the exact valid JSON payload intended for the posting tool, with verified diff line ranges, correctly scoped GitHub suggestion blocks, the user's maintainer voice, and self-contained comments.
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
- perform a thorough, proportionate review of the change and its relevant context
- focus on correctness, architecture, security/performance, test coverage, and documentation/naming

### Thoroughness is coverage, not criticism

Produce a thorough review. Treat thoroughness as complete, proportionate
examination of the PR, not as a target number of findings or a mandate to find
fault. Understand the change's intent and invariants, inspect the full scoped
diff and relevant surrounding code, trace affected callers and lifecycle paths,
and check tests, CI, documentation, compatibility, and prior discussion where
they bear on merge readiness.

Report only concrete, evidence-backed findings that would help the author or
maintainers. Do not invent edge cases, elevate optional preferences, split one
issue into several comments, or add nits merely to make the review appear
substantive. A thorough review may legitimately produce no actionable findings.
When none survive validation, say so directly and briefly state what was
examined plus any residual uncertainty or unverified checks.

Treat `draft the review` as a request to create or revise the exact postable JSON
payload. Treat `show me the draft` after a review was just completed as a
request to display that review as the exact JSON payload, not as a request for
another review pass. A request for a draft is not authorization to post it.

### Show the existing draft

When the user says `show me the draft` or equivalent after this skill just
completed a review in the current task:

- Reuse the completed review and its latest draft state. Do not refresh the PR,
  revisit findings, sample more writing examples, or spawn a fresh independent
  detector merely to display it.
- If the exact JSON payload already exists, return it unchanged. Do not
  reconstruct or reserialize it.
- If the completed review has not yet been rendered as JSON, render its existing
  action, body, comments, anchors, suggestions, and identifiers without adding,
  removing, or substantively rewriting anything. Perform only the mechanical
  JSON parsing and tool-schema checks required by the
  [Exact draft contract](#exact-draft-contract).
- Use the normal draft workflow when no completed review or draft exists in the
  current task, or when the user asks to refresh, revise, recheck, or regenerate
  it.

Showing an existing draft does not authorize posting and does not waive the
current-head checks required immediately before a later post. If those checks
require any payload change, show the replacement JSON before posting.

Default to reviewing the PR from source artifacts unless the user explicitly provides completed findings and asks you to reformat, deduplicate, or post them.

Do not assume the review output has already been provided.

Do not ask follow-up questions just to confirm these defaults. Ask only when something is genuinely ambiguous or the user explicitly asks for customization.

## Review From Source

When the user asks for a review:

1. Identify the target PR and base branch.
Use the current branch if needed. Use the PR base branch by default.

2. Determine whether this is an initial or follow-up review.
Treat it as a follow-up when this reviewer has already completed a substantive pass.

3. Establish the review scope.
- For an initial review, inspect the checked-out diff against the base branch.
- For a follow-up, identify the head SHA from the reviewer's last substantive pass and inspect commits added since it. Read existing review threads, author replies, and resolution status. Build an internal ledger for each earlier concern: requested direction, author response, implementing commit, and whether the current code resolves it. Review the new commits first; expand into unchanged surrounding code only as needed to validate their semantic effects.

4. Check CI status and relevant review and issue discussion, including author replies.

5. Evaluate the areas the user requested thoroughly and proportionately.
Typical axes:
- logic and correctness
- architecture and maintainability
- security and performance
- test coverage
- documentation and naming

6. Produce findings first.
Do not impose a finding quota. Order any findings by severity. Each finding
should explain:
- what is wrong
- when it breaks
- why it matters

If no actionable findings remain after validation, report that result rather
than manufacturing criticism.

7. Keep the summary brief.
Summarize the change only after the findings, unless the user explicitly asked for a longer overview. Keep follow-up summaries especially brief.

8. Run the [Independent BS detector](#independent-bs-detector) on the complete
candidate review, including findings, open questions, and summary.

## Draft Or Post Review Comments

Use this workflow when the user wants findings turned into new or revised
GitHub comments, or wants comments posted. For `show me the draft` after a
review was just completed, use [Show the existing draft](#show-the-existing-draft)
instead.

1. Refresh the PR before drafting.
Read the latest head SHA, current code, and current patch. Do not draft inline locations from a stale review dump or finding summary.

2. Apply [Review continuity and convergence](#review-continuity-and-convergence) before calling a finding new.

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

9. Complete the [Exact draft contract](#exact-draft-contract), including JSON
parsing and tool-schema validation, then run the
[Independent BS detector](#independent-bs-detector) on the exact candidate
payload, including its action, top-level body, inline comments, anchors, and
suggestions.

10. Show or post the review.
For a draft, follow the exact JSON contract below. If the user asks to post, submit one review with all inline comments attached. If the head SHA or any payload field changes after the user approves a draft, show the replacement JSON instead of silently posting a different payload.

## Independent BS Detector

Treat the BS detector as a mandatory, adversarial evidence check for every new
or revised candidate, not a request for tone polishing or reflexive
disagreement. Run it after every user-visible part of such a candidate is
complete and immediately before first presenting or posting that candidate as
the result. The exact final candidate must receive `PASS`.

Do not run a fresh detector when the user only asks to show the review or draft
that this skill just completed in the current task. Follow
[Show the existing draft](#show-the-existing-draft). This exception permits
displaying the existing result; it does not permit changing the candidate or
posting against a stale head.

Spawn one fresh independent agent that did not participate in the review. Use a
no-history or isolated-context spawn so it cannot inherit the primary reviewer's
conversation or rationale. Give it only the candidate output and an initial
evidence packet:

- the current PR diff and head SHA
- the full current files or surrounding code cited by findings
- relevant tests, CI evidence, and repository documentation
- prior review threads and the review ledger for a follow-up
- the exact draft payload when comments will be shown or posted

Give the detector independent read-only access to the repository and PR so it
can inspect callers, tests, documentation, discussion, and CI beyond the initial
packet. Let it request missing artifacts. If access or evidence is insufficient
to test a claim, require `UNVERIFIABLE`; do not let absence of contradictory
evidence count as confirmation.

Do not give the detector the primary reviewer's chain of thought, a defense of
the findings, or instructions to agree. Ask it to try to falsify the candidate
from the artifacts and return a compact verdict for every outgoing component:
each finding, open question, summary, review action, top-level body, inline
comment, anchor, suggestion, and payload identifier or field. Use:

- `KEEP`: the claim, trigger, impact, severity, and requested direction are
  supported
- `REVISE`: a real issue is present, but the wording, confidence, severity,
  scope, remedy, or anchor overstates the evidence
- `DROP`: the claim is unsupported, incorrect, duplicate, stale, pre-existing
  without current-PR relevance, or too speculative to post
- `MISSING`: the supplied artifacts directly expose a material finding the
  candidate omitted; reserve this for concrete correctness or merge-readiness
  concerns, not optional expansion of scope
- `UNVERIFIABLE`: the available evidence or access cannot establish whether the
  component is sound

A candidate with no findings can pass when the review scope was examined and
the evidence exposes no material concern. Do not use `MISSING` merely because
the candidate contains few or no criticisms; require a concrete omitted issue.

Require the detector to cite an exact artifact locator and, for code claims,
the relevant code path supporting each verdict. It must specifically check for:

- a concrete, reachable triggering condition rather than a hypothetical with
  no demonstrated path
- an observable consequence that follows from the current code
- contradictory guards, cleanup, validation, callers, tests, or platform
  behavior that invalidate the claim
- severity and merge posture proportional to impact, likelihood, regression
  status, and PR scope
- duplication or goalpost movement relative to prior review feedback
- accurate current-head paths, lines, diff sides, replacement spans, and
  apply-ready suggestions
- wording that distinguishes fact from uncertainty and removes generic,
  inflated, or performative concern
- a top-level body and review action consistent with the validated findings and
  existing review state

Have the detector end with one overall verdict: `PASS` only when every outgoing
component is `KEEP` and there are no `MISSING` or `UNVERIFIABLE` items;
otherwise `FAIL`. The detector may recommend changes, but it must not edit
files, post the review, or decide the final response.

Adjudicate every non-`KEEP` verdict against the source artifacts. Revise or drop
anything the primary reviewer cannot independently substantiate. Add a
`MISSING` item only after independently validating it under the normal review
scope and continuity rules. Whether the primary agrees or disagrees with a
`FAIL`, revise the candidate or evidence packet and run a new fresh detector;
the primary cannot waive the gate. Any change to outgoing content, payload
fields, identifiers, or supporting evidence invalidates the prior verdict.

Allow at most three detector attempts for one requested review. If the exact
final candidate has not received `PASS` after the third attempt, do not show or
post it. Report that independent validation did not converge, without exposing
the candidate as review output. Do not expose the detector's internal report in
the submitted GitHub review.

For direct posting, re-read the PR head SHA immediately after `PASS` and before
submission. If it changed, rebuild the candidate against the new head and
restart the detector gate. Never post a review validated against a stale head.

If an independent agent cannot be spawned or cannot inspect the necessary
artifacts, do not show or post the candidate review and do not claim the gate
passed. Tell the user that the independent validation is blocked and identify
the missing capability or evidence.

## Exact Draft Contract

When the user asks to create or revise a draft:

- Select the actual posting tool or endpoint first.
- Return one fenced `json` block containing the exact argument object or request body that will be sent. Use the active tool's real field names and nesting; do not translate it into a generic review schema.
- Keep the JSON parse-valid and complete. Include every field that will be sent, preserve every comment body byte-for-byte, and omit fields that will not be sent. Do not use placeholders, ellipses, comments, or trailing commas.
- Encode Markdown and suggestion blocks inside JSON strings with the required escapes, including `\n` and `\t`.
- Do not present a separate prose or Markdown version of the review that could drift from the payload.
- Use the displayed object unchanged when posting. Re-render and re-present it if validation requires any change.

If repository or PR identifiers are arguments to the selected tool, include them in the JSON. If they are path parameters outside a REST request body, identify the endpoint immediately before the JSON block, then show the exact request body.

Before invoking the BS detector, parse the JSON with a real JSON parser and
verify it against the selected tool schema. Treat any later serialization or
schema-driven change as a new candidate that requires another detector pass.

When the user asks to show the draft that was just completed, follow
[Show the existing draft](#show-the-existing-draft). Do not treat that display
request itself as a reason to invoke the detector again.

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
- Do not mention the drafting process, internal analysis or AI usage, the user's prompt, private conversation, or invisible context.
- Avoid references such as `as we discussed`, `from the earlier review`, or `the issue I mentioned` unless the referenced text is part of the same visible GitHub thread and the comment still restates the necessary context.
- Restate any essential repository or prior-discussion context instead of requiring the author to chase it.
- Use links and citations as supporting evidence, not as a substitute for the explanation.

## Review Output Shape

For a source review, prefer this structure:

1. Findings by severity, or an explicit statement that no actionable findings
   survived validation.
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

## Review Continuity and Convergence

Before producing each follow-up finding, check the review ledger:

- Do not create a new comment for the same concrete failure already reported. If it remains unresolved, continue the existing thread when possible.
- Treat a different failure mode introduced by the response to earlier feedback as new, but connect it to the underlying invariant instead of presenting it as unrelated.
- If earlier guidance omitted or contradicted an important invariant, say so plainly and provide the corrected invariant rather than silently moving the goalposts.
- Post a finding outside the latest delta only when the new changes caused or exposed it, or it is a clear high-severity blocker. Otherwise classify it as follow-up work.

When several findings share a subsystem or lifecycle, consolidate them around the underlying invariant and acceptance criteria. Prefer one comment with representative tests over successive comments for isolated edge cases. Before requesting another change, ask internally:

- Why is this surfacing now, and could it reasonably have been raised earlier?
- Does it refine or conflict with previous guidance?
- Can related failure modes be addressed together?

Never suppress a genuine blocker because of review fatigue. Distinguish a current-PR blocker from reasonable follow-up work using impact, likelihood, regression status, and the PR's stated scope; a narrow, low-impact, or pre-existing edge case does not automatically block the PR.

State blocker versus follow-up status when it prevents churn, and do not re-explain the full history unless the author needs it to act.

When classifying findings, use `not new` only for the same concrete issue, `same theme, new formulation` for a different failure mode in an area discussed earlier, and `new` when neither appeared before. Separate author acknowledgement from resolution, using replies and current code to decide the latter.

## GitHub Tools

When GitHub connector tools are available, prefer them for:
- locating the PR for the current branch
- reading PR metadata, comments, and reviews
- checking CI status
- fetching file patches for inline placement
- posting the final review

Use repository code and local diff context as the source of truth for whether a prior concern is actually resolved.
