# Initial Review Pre-Review

Complete this stage on every initial source review before detailed hunk review.
Decide whether the change belongs in the project, as well as whether it works.
Scale the investigation to the change; a small fix can need only brief answers.
Do not require the author to fill out a template when the artifacts already
answer the questions.

Read the PR description, commit messages, linked issue or design, relevant
discussion, and diff overview. Inspect the current tree, public contracts, and
relevant history enough to test the premise and compare alternatives. Targeted
code reads belong here when they establish the need or design constraints.
Keep a short internal record of each answer, its supporting artifact, and any
material uncertainty. Do not mistake missing explanation for a proven defect.

## Five questions

1. **What is the problem?** Identify the concrete limitation, failure, or cost
   in the current tree. Separate the user's need from the proposed mechanism.
   Check any reproducer, measurements, or reported use case against current
   behavior. If the need remains unclear after reading the available context,
   ask a focused question that names the missing scenario or evidence.

2. **Is it worth solving?** Identify who encounters the problem, how realistic
   the trigger is, and what happens if nothing merges. Distinguish measured
   impact from assumptions. Check existing ways to achieve the same result.
   Weigh the benefit against the maintenance cost the project inherits.
   Working code, effort spent, revision count, and other reviewers' approvals
   do not establish the premise. A recommendation not to merge is legitimate
   when the evidence supports it; an unsupported use case needs clarification.

3. **Is there a simpler way?** Start from the problem and the current tree,
   independently of the proposed solution. Look for existing helpers,
   composition, or a smaller change with fewer concepts. Compare alternatives
   against the same requirements and constraints. When a simpler alternative
   materially improves the design, include a small code sketch or pseudocode
   that makes the tradeoff concrete. Label illustrative code and keep it
   outside apply-ready GitHub suggestion blocks. Do not expand review into
   implementation work or propose a rewrite based only on personal preference.

4. **Will the APIs and layers last?** Check which layer owns the behavior and
   whether the change duplicates an existing capability. Examine public APIs,
   configuration, stored formats, and compatibility promises where relevant.
   Assess the long-term contract and migration burden before accepting a new
   surface. Ask whether an abstraction serves the demonstrated need without
   creating a special-case path or speculative framework. Apply the project's
   actual stability policy; do not assume every internal API is permanent.

5. **Is it good taste?** Make an engineering judgment about complexity,
   cohesion, helper choice, and fit with the project. Distinguish cosmetic
   preferences from design costs: a local variable name or line wrap is a
   nit; convoluted control flow, the wrong helper, or unnecessary concepts
   can be substantive. State the concrete maintenance or reasoning burden
   and the constraint a better design must satisfy. Do not post subjective
   dislike as a correctness defect or invent criticism to fill this step.

## Act on the answers

- **Premise and design supported:** Continue the full scoped review, including
  correctness, security, performance, tests, CI, and documentation. This stage
  complements those checks and does not delegate them to an assumed bot.
- **Essential answer missing:** Focus the review on the unresolved need or
  design decision. Inspect enough code to make the question precise, then
  defer detailed polish that depends on the answer. State the limited scope;
  do not present an all-clear or claim a complete implementation review.
- **Premise or design fails on evidence:** Lead the top-level body with that
  judgment and the concrete reason. Explain the required direction or a
  simpler alternative. Defer polish on an approach that should not land in
  its current form. Keep any independently established material defects, but
  do not bury the design decision beneath a list of hunk comments.

Use the normal draft workflow for each outcome, including action selection,
the communication check, exact JSON, and independent validation. An unresolved
premise question prevents an all-clear approval; it does not by itself justify
`REQUEST_CHANGES`. Do not require a finding quota or output five boilerplate
answers. In follow-ups, preserve the earlier decisions and revisit them only
when new evidence or changes warrant it. More implementation fixes do not
answer an outstanding question about why the change belongs in the project.

Adapted from Alexei Starovoitov's
[Five questions every patch has to answer](https://lore.kernel.org/bpf/20261016224310.3135990-1-alexei.starovoitov@gmail.com/)
(16 October 2026), using the message text supplied by the user. The questions
guide this pre-review; BPF-specific bot coverage and submission requirements
do not become assumptions about other repositories.
