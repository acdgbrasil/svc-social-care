---
title: "Flag large PRs that exceed recommended size"
scope: "pull_request"
severity_min: "medium"
buckets: ["style-conventions"]
enabled: true
---

## Instructions

Use `pr_total_lines_changed` and `pr_total_files` to evaluate PR size.

Guidelines:
- **Ideal**: < 400 lines changed, < 15 files
- **Warning** (medium): 400-800 lines or 15-30 files — suggest splitting if possible
- **Large** (high): > 800 lines or > 30 files — strongly recommend splitting into stacked PRs

When flagging, suggest how the PR could be split by bounded context or layer:
- Domain changes in one PR
- Application layer (use cases) in another
- IO layer (controllers, repositories, migrations) in another

Exceptions (do NOT flag):
- PRs that only add/modify test files
- PRs with title containing `chore` or `refactor` that are purely mechanical (rename, formatting)
- Migration files (these are inherently verbose)
- Generated code or lock files

## Examples

### Flag
```
PR with 1200 lines changed across 25 files touching Registry, Assessment, and Care contexts.
Suggestion: split into 3 PRs — one per bounded context.
```

### Don't flag
```
PR with 600 lines but 500 are new test files for existing use cases.
This is fine — test-heavy PRs don't need splitting.
```
