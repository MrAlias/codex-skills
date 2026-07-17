# GitHub Review Payloads and Suggestions

Read this reference before drafting or posting a GitHub review.

## Authoritative Documentation

Open and read the current GitHub documentation relevant to the selected transport and suggestion blocks before constructing the payload. Do not rely on remembered syntax when current official documentation is available.

- [Create a pull request review](https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request)
- [Create a pull request review comment](https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request)
- [Review proposed changes and make suggestions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/reviewing-proposed-changes-in-a-pull-request)

Inspect the selected posting tool's current schema as well. Use its exact names and nesting. REST uses fields such as `commit_id`, `start_line`, and `start_side`; GraphQL or connector tools may use different casing or wrappers.

## Exact Payload

Choose the transport before rendering a draft. Show the exact JSON accepted by that transport:

- For a connector or MCP tool, show its complete argument object, including repository and PR identifiers when they are tool arguments.
- For `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews`, show the exact request body and identify the endpoint separately.
- Do not invent a normalized intermediate schema.
- Do not add fields for readability if they will not be sent.
- Keep comment Markdown inside each JSON `body` string. Escape newlines, tabs, quotes, and backslashes so the displayed payload parses as JSON.

This is an illustrative REST request body, not a template to copy without checking the active transport:

```json
{
  "commit_id": "0123456789abcdef0123456789abcdef01234567",
  "body": "There is one correctness issue to address before this is ready.",
  "event": "REQUEST_CHANGES",
  "comments": [
    {
      "path": "pkg/cache/cache.go",
      "start_line": 87,
      "start_side": "RIGHT",
      "line": 89,
      "side": "RIGHT",
      "body": "This drops the storage error, so callers continue as if the cache entry was persisted. Please return the error here.\n\n```suggestion\nif err := cache.Store(ctx, value); err != nil {\n\treturn fmt.Errorf(\"store cache entry: %w\", err)\n}\n```"
    }
  ]
}
```

## Line And Range Placement

Refresh the PR head SHA and patch immediately before drafting, and refresh them again before posting.

For each inline comment:

1. Use the exact repository-relative `path` from the current patch.
2. Anchor only to lines that GitHub exposes in the current PR diff.
3. Prefer blob line coordinates over deprecated diff `position` coordinates when the transport supports them.
4. For a single-line comment, set `line` and `side`; omit `start_line` and `start_side` unless the tool requires them.
5. For a multi-line comment, set `start_line`/`start_side` to the first selected line and `line`/`side` to the last selected line.
6. Use `RIGHT` for additions and current-side context lines. Use `LEFT` for deletions. Verify mixed or unusual ranges against the active API rather than inferring them.
7. Confirm the range is contiguous, minimal, and attached to the code discussed by the body.
8. Include the latest `commit_id` when the transport supports it so the review cannot silently attach to an older head.

Do not derive blob line numbers from terminal display numbers, diff offsets, stale patches, or a pasted finding. Read the hunk headers and both sides of the current patch. If a valid diff anchor cannot be proven, use the top-level review body instead of fabricating an inline location.

## Suggestion Blocks

Use a suggestion when the reviewer can provide a concrete local edit that the author should be able to apply directly. Prefer prose for architectural direction, incomplete sketches, uncertain fixes, changes spanning unrelated locations, or edits that cannot be represented by one precise contiguous range.

Use GitHub's exact fence with no language suffix:

````md
Explanation of the bug and why this replacement fixes it.

```suggestion
complete replacement text
```
````

Treat the suggestion body as the complete replacement for the selected line range:

- Select the smallest contiguous range that the replacement needs.
- Make `start_line` through `line` match that exact range.
- Put only replacement text inside the fence. Do not include diff markers, line numbers, explanatory prose, placeholders, or an extra Markdown language tag.
- Preserve the file's exact indentation and formatting.
- Omit unchanged surrounding lines whenever the edit can remain valid without them. Include an unchanged line only when GitHub needs it as part of a contiguous replacement or insertion anchor.
- Re-read the resulting code mentally or apply the replacement in a temporary worktree when practical. Do not offer a suggestion that is merely illustrative, syntactically incomplete, or inconsistent with repository conventions.

In JSON, the comment above becomes one escaped string, for example:

```json
{
  "body": "Explanation of the bug and why this replacement fixes it.\n\n```suggestion\ncomplete replacement text\n```"
}
```

## Preflight

Before displaying the draft:

1. Reconfirm that each finding is still present and not duplicated by existing review feedback.
2. Reconfirm the head SHA, patch, path, line or span, and side for every inline comment.
3. Reconfirm that each suggestion is a complete replacement for exactly its anchored span.
4. Parse the final JSON with a real parser.
5. Check the object against the selected posting tool's current schema.
6. Present that exact object without a second, divergent prose rendering.

Before posting, repeat the head and line-placement checks. If anything changes, regenerate the JSON and show the changed payload for approval.
