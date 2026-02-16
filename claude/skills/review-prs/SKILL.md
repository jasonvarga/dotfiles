---
name: review-prs
description: Review open GitHub pull requests. Use when reviewing PRs, checking PR status, or auditing open pull requests on a repository.
argument-hint: "[--repo owner/repo] [--output dir]"
disable-model-invocation: true
allowed-tools: Bash(gh *), Bash(mkdir *), Bash(rm *)
---

# Review Pull Requests

Review open pull requests on a GitHub repository, creating detailed markdown review files.

## Arguments

Parse from `$ARGUMENTS`:
- `--repo` - Repository to review (default: current repo via `gh repo view --json nameWithOwner -q .nameWithOwner`)
- `--output` - Output directory for reviews (default: `pr-reviews`)

## Instructions

1. **Parse arguments** from: $ARGUMENTS

2. **Determine repository**: If no `--repo` provided, get current repo:
   ```bash
   gh repo view --json nameWithOwner -q .nameWithOwner
   ```

3. **Create output directory** if it doesn't exist

4. **Fetch open PRs**:
   ```bash
   gh pr list --repo <repo> --state open --json number,title,author,mergeable --limit 100
   ```

5. **Filter PRs**:
   - Skip PRs with `mergeable: "CONFLICTING"`
   - Report which PRs were skipped due to conflicts

6. **Ask how many PRs to review** using AskUserQuestion:
   - Show the total number of mergeable PRs available
   - Options: "All (Recommended)", "5", "10", "20"
   - Default/first option should be "All"

7. **Clean up merged PR reviews**:
   - Check existing `.md` files in the output directory
   - For each file named `<number>.md`, check if that PR is still open
   - Delete review files for PRs that have been merged or closed
   - Report which files were cleaned up

8. **Review each PR in parallel** using the Task tool with `subagent_type: general-purpose`. Each subagent should:
   - Fetch PR details: `gh pr view <number> --repo <repo>`
   - Fetch PR diff: `gh pr diff <number> --repo <repo>`
   - Analyze the changes thoroughly
   - Write a review to `<output>/<number>.md` with the format from [review-template.md](review-template.md)

9. **Report results** with a summary table:
   | PR | Title | Author | Recommendation |
   |----|-------|--------|----------------|
   | [#123](url) | Title | author | Approve/Request Changes/Needs Discussion |

   Include counts: total reviewed, approved, needs changes, skipped due to conflicts, cleaned up.