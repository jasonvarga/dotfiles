---
name: commit
description: >-
  Commit pending changes using atomic commits. Use when the user asks to
  "commit", "commit my changes", or "make a commit". Groups related changes
  into separate logical commits. Never pushes. Stops on merge conflicts and
  asks before committing a mix of staged/unstaged changes.
---

# Commit

Commit the working tree's pending changes as a series of atomic commits — each commit a single logical change. **Never push.**

## Instructions

1. **Check for an in-progress merge with conflicts**:
   ```bash
   git status --porcelain
   ls -1 .git/MERGE_HEAD 2>/dev/null
   ```
   - If a merge is in progress (`MERGE_HEAD` exists) and there are conflicted files (`UU`, `AA`, `DD`, `U`/`A`/`D` markers in status), **stop**. Tell the user there are conflicts. Offer to resolve them, but if you do, have the user review your resolution **before** you commit anything.

2. **Assess staged vs unstaged**:
   ```bash
   git status --porcelain
   ```
   - If there is a **mix** of staged and unstaged changes, the user likely staged things on purpose. **Confirm first**: commit only what's staged, or everything? Wait for their answer.
   - If everything is unstaged (or everything is already staged), proceed.

3. **Review what's changing** to plan the commits:
   ```bash
   git diff           # unstaged
   git diff --staged  # staged
   ```
   - Group changes into atomic commits — each a single coherent change. Unrelated changes within the same file may need `git add -p` to split.

4. **Match the repo's commit message style** by inspecting recent history:
   ```bash
   git log --oneline -20
   ```
   - Follow the prevailing convention (e.g. conventional-commits prefixes, capitalization, tense). If none is apparent, write concise imperative subjects.

5. **Stage and commit each group**:
   ```bash
   git add <paths>      # or: git add -p <paths> to split a file
   git commit -m "<message>"
   ```
   - Repeat per logical group.
   - Per global instructions, do not pass options to `rm`. Do not amend existing commits unless asked.

6. **Do not push.** Report the commits created (`git log --oneline` of the new commits).
