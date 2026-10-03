---
name: security-advisory-draft
description: Analyse a vulnerability report and draft GitHub security advisory content from it. Use when creating a security advisory, drafting CVE/advisory text from a vuln report or GHSA, or when the user needs title, description, CVSS, and CWE for an advisory.
---

# Draft Security Advisory from Vulnerability Report

Analyse a vulnerability report, decide whether it's a real vulnerability, and if so produce advisory content (title, description, CVSS, CWE, versions) matching the style of the project's existing GitHub security advisories.

Do not create, edit, publish or change the state of any GitHub advisory, issue, PR or comment. Read-only `gh` calls are fine.

## When to use

- User provides or points to a vulnerability report (a GHSA id or link, a PDF, markdown, pasted text) and wants advisory text.
- User is about to open a GitHub security advisory and needs structured content.

## Instructions

1. **Read the vulnerability report**
   - A GHSA: `gh api repos/OWNER/REPO/security-advisories/<GHSA-ID>`. Otherwise use the path or content the user provides.
   - Identify: affected component, impact (who can do what, what data is exposed), root cause, and any suggested remediation.

2. **Analyse it against the code.** Read the code the report points at rather than trusting its description. Consider:
   - What is the vulnerability class and root cause?
   - Who can exploit it, and under what conditions?
   - What is the actual impact (data exposure, privilege escalation, denial of service, etc.)?
   - What versions are affected?
   - Is the reported CVSS/CWE accurate? If not, what would you assign and why?
   - Are there any gaps, inconsistencies, or unclear claims in the report?
   - Is this actually a valid vulnerability at all?

3. **Decide the verdict.** Either **Valid**, or one of these decline categories:
   - **Invalid** — not a vulnerability.
   - **Duplicate** — of another report or advisory; name it.
   - **Already mitigated** — already patched, or blocked by something the report missed.
   - **By design** — intended behaviour.
   - **Won't fix** — real, but not something the project will address.

   **If it's a decline, don't draft.** A full draft for something that will never be published is just noise. Output only the verdict, a one-paragraph rationale, and optionally a brief courtesy reply to the reporter. Skip the remaining steps.

4. **Match existing advisory style**
   - Fetch the repo's recent **published** advisories for tone and structure (excludes drafts/triaged/closed):
     ```bash
     gh api "repos/OWNER/REPO/security-advisories?state=published" --jq '.[0:5] | .[] | {summary, severity, description: (.description | split("\r\n")[0:25] | join("\n"))}'
     ```
   - Replace `OWNER/REPO` with the target repo (e.g. `statamic/cms`) or infer from context.
   - Prefer short summary titles; use "Missing authorization…", "Privilege escalation via…", etc. when they fit.
   - For the description use:
     - **### Impact** — One or two sentences: who can do what, and what is exposed or broken. Keep it quite vague – don't need specifics on how to exploit, what endpoints are affected, etc.
     - **### Patches** — "This has been fixed in X.Y.Z (and 6.x.y)."
   - For the patches/versions:
     - If the conversation context has mentioned this issue has been fixed, infer the version.
     - Otherwise, or if unsure, use a placeholder.

5. **Assign CVSS and CWE**
   - Determine the CVSS score yourself.
   - Determine the CWE yourself.
   - If the report already has a CVSS score and/or CWE, compare them to your own and explain whether and why your opinion is different.

6. **Output the draft**
   - **Title** — One line, same style as existing advisories (e.g. "Missing authorization in relationship endpoint allows access to restricted entries and terms").
   - **Description (Markdown)** — `### Impact` and `### Patches`; user can paste into the advisory and fill in versions. Note whether version numbers in Patches are placeholders to update when the fix is released.
   - **CVSS** — Score and optional vector string (e.g. "4.3 (Medium) — AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N").
   - **CWE** — Id and name (e.g. "CWE-862: Missing Authorization").
   - **Affected Versions** — A string that can be pasted into the advisory (e.g. <5.73.12, <6.7.2).
   - **Patched Versions** — A string that can be pasted into the advisory (e.g. 5.73.12, 6.7.2).

## When writing to a Solo scratchpad

Because you were asked to save it, or you're running under the `security-advisory-orchestrator`, which reads the metadata block. Use this exact structure, every time:

```
- Analysis model: <model(s)>
- Verdict: 📝 **Valid — <severity> (<CVSS score>)**

## Analysis
<your analysis from step 2>

## Advisory Draft
<the draft from step 6>
```

For a decline, `## Advisory Draft` is replaced by `## Decline` holding the rationale and any suggested reporter reply, and the verdict line uses the category's emoji and exact name, optionally followed by ` — <short detail>`:

| Category | Verdict line |
|---|---|
| Invalid | `- Verdict: 🚫 **Invalid**` |
| Duplicate | `- Verdict: 🔁 **Duplicate — GHSA-xxxx-xxxx-xxxx**` |
| Already mitigated | `- Verdict: 🛡 **Already mitigated**` |
| By design | `- Verdict: 📐 **By design**` |
| Won't fix | `- Verdict: 🙅 **Won't fix**` |

- **Name the scratchpad** `Advisory <GHSA-ID> — <GHSA summary>`, unless you were given an exact name.
- **The metadata block comes first and stays bulleted.** Solo's scratchpad view collapses consecutive plain lines onto one rendered line.
- **`Analysis model`** — name the model you are, from your system context (e.g. `Opus 5`), not a generic "Claude". If more than one model contributed, list each in order.
- **`Verdict`** is the single source of truth for the outcome. Keep it in sync with the sections below whenever discussion changes your conclusion.
- **Write the pad only once it's complete.** Under an orchestrator, a `Verdict:` line is read as "finished".
