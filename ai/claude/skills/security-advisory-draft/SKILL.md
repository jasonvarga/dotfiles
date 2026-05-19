---
name: security-advisory-draft
description: Draft GitHub security advisory content from a vulnerability report. Use when creating a security advisory, drafting CVE/advisory text from a vuln report, or when the user needs title, description, CVSS, and CWE for an advisory.
---

# Draft Security Advisory from Vulnerability Report

Produce advisory content (title, description, CVSS, CWE, versions) from a vulnerability report. Match the style of the project’s existing GitHub security advisories.

## When to use

- User provides or points to a vulnerability report (e.g. PDF, markdown) and wants advisory text.
- User is about to open a GitHub security advisory and needs structured content.

## Instructions

1. **Read the vulnerability report**
   - Use the path or content the user provides (e.g. `vulnerability-report.pdf` or pasted text).
   - Identify: affected component, impact (who can do what, what data is exposed), root cause, and any suggested remediation.

2. **Match existing advisory style**
   - Fetch the repo’s recent advisories for tone and structure:
     ```bash
     gh api repos/OWNER/REPO/security-advisories --jq '.[0:5] | .[] | {summary, severity, description: (.description | split("\r\n")[0:25] | join("\n"))}'
     ```
   - Replace `OWNER/REPO` with the target repo (e.g. `statamic/cms`) or infer from context.
   - Prefer short summary titles; use “Missing authorization…”, “Privilege escalation via…”, etc. when they fit.
   - For the description use:
     - **### Impact** — One or two sentences: who can do what, and what is exposed or broken. Keep it vague - don't need specifics on how to exploit.
     - **### Patches** — “This has been fixed in X.Y.Z (and 6.x.y).”
   - For the patches/versions:
     - If the conversation context has mentioned this issue has been fixed, infer the version.
     - Otherwise, or if unsure, use a placeholder.

3. **Assign CVSS and CWE**
   - Determine the CVSS score yourself.
   - Determine the CWE yourself.
   - If the report already has a CVSS score and/or CWE, compare them to your own and explain whether and why your opinion is different.

4. **Output the following**

   - **Title** — One line, same style as existing advisories (e.g. “Missing authorization in relationship endpoint allows access to restricted entries and terms”).
   - **Description** — Markdown with `### Impact` and `### Patches`; user can paste into the advisory and fill in versions.
   - **CVSS** — Score and optional vector string (e.g. “4.3 (Medium) — AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N”).
   - **CWE** — Id and name (e.g. “CWE-862: Missing Authorization”).
   - **Affected Versions** — Provide the list of versions affected by the vulnerability as a string that can be pasted into the advisory. (e.g. <5.73.12, <6.7.2)
   - **Patched Versions** — Provide the list of versions fixed by the vulnerability as a string that can be pasted into the advisory. (e.g. 5.73.12, 6.7.2)

## Output format

Provide a clear, copy-paste-friendly block for the user:

- **Title:** [one-line summary]
- **Description (Markdown):** [Impact + Patches]
- **CVSS:** [score and optional vector]
- **CWE:** [id and name]
- **Affected Versions:** [comma-separated list of version constraints]
- **Patched Versions:** [comma-separated list of versions]

Note in the description whether version numbers in Patches are placeholders and should be updated when the fix is released.

Do not attempt to open or modify the GitHub advisory yourself.