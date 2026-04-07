---
title: "PR title must follow Conventional Commits"
scope: "pull_request"
severity_min: "high"
buckets: ["style-conventions"]
enabled: true
---

## Instructions

The PR title must follow the Conventional Commits specification used by this organization.

Valid prefixes: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`

Breaking changes use `!` suffix: `feat!:`, `fix!:`

Rules:
- Title must start with one of the valid prefixes
- The description after the prefix should be lowercase and concise
- Scope is optional but encouraged for multi-context repos: `feat(registry):`, `fix(assessment):`
- Valid scopes for social-care: `registry`, `assessment`, `care`, `protection`, `configuration`, `auth`, `infra`

Use the PR variable `pr_title` to validate.

## Examples

### Bad example
```
Added new patient registration endpoint
Update housing condition
Fix bug in referral
```

### Good example
```
feat(registry): add family member registration endpoint
fix(assessment): correct housing condition validation for rural areas
chore: update SQLKit dependency to 3.30.0
```
