# Review Template

Write each PR review with this structure:

```markdown
# PR #<number>: <title>

**Author:** <author>
**URL:** <pr_url>
**Branch:** <head> → <base>

## Summary

Brief description of what the PR does and why.

## Changes Overview

| File | Change |
|------|--------|
| path/to/file.ext | What changed and why |

## Code Quality Assessment

- Is the code well-written and idiomatic?
- Are there any bugs, edge cases, or logic errors?
- Is there code duplication that should be refactored?
- Are there any security concerns?

## Testing

- Are there tests? Are they adequate?
- Do tests cover edge cases?
- Are there missing test scenarios?

## Recommendation

**Approve** / **Request Changes** / **Needs Discussion**

Explain the reasoning.

## Suggested Changes

List specific improvements needed. Be precise:
- Reference specific lines or code blocks
- Provide code examples when helpful
- Distinguish between blocking issues and nice-to-haves
```

## Review Guidelines

Focus on substance over style:
- Correctness: Does it work? Are there bugs?
- Completeness: Does it fully solve the problem?
- Testing: Is it adequately tested?
- Maintainability: Is the code clear and maintainable?

Avoid nitpicking:
- Minor formatting issues (unless egregious)
- Stylistic preferences not in project conventions
- Trivial naming suggestions