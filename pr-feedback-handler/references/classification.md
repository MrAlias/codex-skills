# Feedback Classification

Use these categories when turning raw PR feedback into an action plan.

## Categories

- `valid`: clearly correct and actionable; implement it
- `invalid`: should not be implemented because it is incorrect, out of scope, or would regress behavior
- `already_satisfied`: the current code already does it, or another selected change fully covers it
- `duplicate`: repeats another item in substance
- `informational`: observation or praise with no requested change
- `ambiguous`: intent is not clear enough to implement safely without asking
- `explanation_only`: better handled by a written response than a code change

## Default Heuristics

Treat feedback as `valid` when it:

- identifies a real bug, missing test, regression risk, or maintainability issue
- aligns with the PR's scope and repository conventions
- can be implemented without inventing product requirements

Treat feedback as `invalid` when it:

- contradicts known requirements or current accepted behavior
- would introduce a regression or weaken correctness
- is based on a misunderstanding of the code or diff
- requests a scope expansion the user did not ask for

Treat feedback as `already_satisfied` or `duplicate` when that is the simplest true explanation. Do not implement the same ask twice under different wording.

Treat feedback as `ambiguous` when a safe implementation depends on a product, API, or UX choice that is not established by the repo or the PR context.

## Reporting Rules

When reporting non-addressed items:

- name the item or cluster briefly
- state the category
- give one short reason

Examples:

- `Not addressed: rename API to match suggestion` (`invalid`) because it would break the existing external contract.
- `Not addressed: add another null check in parser` (`already_satisfied`) because the current guard already covers that path.
- `Not addressed: move this to a background job` (`ambiguous`) because that requires a product and operational decision not established in the PR.
