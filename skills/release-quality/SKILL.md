---
name: release-quality
description: >-
  Use when a user is preparing to publish a project publicly, create an open source repo, make a private repository public, ship a first/v1.0 release, or asks for pre-release/open-source quality checks, including Scorecard/security/license/CI readiness.
---

# Release Quality

Use this skill to run a public-release preflight before a project becomes visible to strangers. The goal is not to block every imperfect release; it is to gather evidence, separate real blockers from acceptable rough edges, and make the user choose when the tradeoff is product, legal, security, or reputation-sensitive.

## Core Principle

Evidence first, decision second. Tool scores are signals, not automatic gates. Do not make a repository public, create a public release, choose a license, rewrite history, rotate credentials, or make behavior-changing fixes without explicit user confirmation.

## When to Use

Use this skill when the user says things like:

- "make this repo public", "turn this private repo public", "open source this"
- "prepare for public release", "ship v1.0", "first release", "publish the project"
- "run a preflight", "public-ready check", "release quality check"
- "scorecard", "OpenSSF", "supply-chain", "security posture", "repo hygiene"

Do not use it for ordinary feature work, private internal releases, or a narrow bugfix unless the user connects the work to a public release.

## Preflight Workflow

1. **Confirm the release target.** Identify whether this is a new public repo, a private-to-public conversion, a package publish, or a GitHub release/tag. If the target is obvious, proceed; otherwise ask one short question.
2. **Freeze the evidence point.** Check `git status`, current branch, remote URL, latest commit, and whether there are uncommitted changes. Report if the working tree is not the exact state that will be published.
3. **Review the public surface.** Inspect README/quickstart, LICENSE, SECURITY.md, CONTRIBUTING, examples, screenshots, package metadata, `.gitignore`, public URLs, private notes, generated files, and large/binary artifacts.
4. **Run local project checks.** Prefer existing repo commands for lint, format, typecheck, tests, build, packaging, and smoke tests. Do not invent a heavy toolchain if the repo has none.
5. **Run release-quality tools.** Use the tool table below. If a tool is missing, say whether it is worth installing for this release instead of silently skipping it.
6. **Triage findings.** Classify each issue as Blocker, User Decision, Fix Now, or Backlog.
7. **Ask for decisions.** Present the smallest set of decisions needed before public release, with evidence and consequences.

## Tool Prechecks

| Area | Preferred check | Notes |
|---|---|---|
| OpenSSF posture | `scorecard --repo=github.com/OWNER/REPO --format=json` | Use `GITHUB_AUTH_TOKEN` when needed. Scorecard supports `default` and `json` formats. Some checks need GitHub context and may be incomplete before the repo is public or when token permissions are limited. |
| GitHub Actions security | `zizmor .github/workflows` or `uvx zizmor .github/workflows` | Run when workflows exist. Pay special attention to `pull_request_target`, broad permissions, credential persistence, and unpinned third-party actions. |
| Secrets | `gitleaks detect --source . --redact` | Treat confirmed secrets as blockers. Decide with the user whether to rotate, remove, and/or rewrite history. |
| Dependency vulnerabilities | Existing ecosystem command, `osv-scanner`, or `pip-audit` / `cargo audit` / `npm audit` / `pnpm audit` | Prefer the project's package manager and lockfile. Avoid broad upgrades unless the user accepts release risk. |
| CI and release path | Existing test/build/package commands | Verify the documented quickstart and release artifact path, not just whatever command is convenient. |
| License and policy | README, LICENSE, SECURITY.md, package metadata | Never choose a license on behalf of the user unless they already gave one. |

For Scorecard results, look beyond the aggregate score. Prioritize high-risk checks such as `Branch-Protection`, `Token-Permissions`, `Vulnerabilities`, `Security-Policy`, `Code-Review`, `Pinned-Dependencies`, `Binary-Artifacts`, `Signed-Releases`, `SAST`, `CI-Tests`, and `Maintained`.

## Triage Rules

| Class | Meaning | Examples | Action |
|---|---|---|---|
| Blocker | Public release should not proceed without addressing it | Confirmed secret, private customer data, missing license for intended open source release, broken advertised install path, known exploitable vulnerability | Stop and ask for user decision or approval to fix |
| User Decision | More than one reasonable choice exists | License choice, whether to rewrite Git history, acceptable Scorecard gaps, delaying release, branch protection policy, signed release policy | Present options and consequences |
| Fix Now | Low-risk cleanup aligned with stated intent | README typo, stale private link, missing `.env.example`, harmless `.gitignore` addition, obvious docs mismatch | Offer or apply focused fix depending on permissions |
| Backlog | Useful but not release-blocking | Code of Conduct, richer examples, badge polish, fuzzing for low-risk library, non-critical Scorecard score improvement | Record as follow-up, do not block by default |

## Report Shape

Use this structure for the user-facing result:

```markdown
## Release Readiness
Status: Ready / Ready after decisions / Not ready

Evidence:
- `command`: key result

Findings:
- [Blocker/User Decision/Fix Now/Backlog] Area: evidence -> recommendation

Decisions needed:
1. Decision, options, recommended default

Safe fixes I can apply now:
- Focused fix and why it is low risk
```

Keep the report short enough for the user to make decisions. Put raw tool output in files only when useful, and make sure reports do not contain secrets.

## Common Mistakes

- Making the repo public with `gh repo edit --visibility public` before the user explicitly says yes.
- Treating a low Scorecard aggregate score as an automatic no-go, instead of explaining which checks matter for this release.
- Auto-selecting MIT/Apache/GPL because "open source needs a license."
- Rewriting Git history, deleting tags, or rotating credentials without a decision.
- Running checks on a dirty working tree and presenting the result as the release state.
- Scanning only current files when the risk is in Git history.
- Uploading or committing scanner reports that include sensitive paths, dependency metadata, or secrets.

## Red Flags

| Pressure | Risk | Better response |
|---|---|---|
| "Don't make it complicated" | Skipping the checks that matter most before public exposure | Keep the preflight small, but still cover secrets, license, advertised install path, Scorecard, and release visibility. |
| "Just fix the low scores" | Chasing metrics instead of release risk | Read the underlying checks, then sort by release impact and user decision needs. |
| "Make it public when done" | Treating visibility as an implementation detail | Prepare the repo, report readiness, and ask for explicit confirmation before changing visibility. |
| "Pick a license for me" | Making a legal/product decision for the user | Explain common options only if asked, then have the user choose. |
| "Remove the secret from the file" | Leaving leaked credentials valid in history | Ask whether to rotate credentials and whether history rewrite is required. |

## Example

User: "我要今天发 v1.0 并把 GitHub repo 公开。跑下安全检查就行，分数低的你直接修。"

Response pattern:

```markdown
我会先跑公开发布预检，但不会直接把低分项都改掉。Scorecard、secret 扫描、Actions 安全和依赖漏洞会产出证据；确认 secret、许可证、公开可见性、删历史、行为性升级这类事项需要你决策。低风险文档和配置清理我会单独列为可直接修复项。
```
