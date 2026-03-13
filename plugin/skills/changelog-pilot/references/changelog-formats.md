# Changelog Formats Reference

## Keep a Changelog (Recommended Default)

Based on [keepachangelog.com](https://keepachangelog.com/en/1.1.0/).

### Structure
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.3.0] - 2026-03-13

### Added
- User profile settings page with avatar upload (#142)
- Dark mode toggle that persists across sessions (#138)

### Changed
- Auth service now returns structured error objects instead of strings
- Updated axios to 1.6.0

### Deprecated
- `legacyAuth()` method — use `authenticate()` instead, will be removed in v2.0

### Removed
- Dropped support for Node.js 16

### Fixed
- Login redirect loop on Safari when using SSO (#141)
- Date picker showing wrong dates in non-UTC timezones (#136)

### Security
- Patched XSS vulnerability in markdown renderer (#140)

## [1.2.3] - 2026-02-28

### Fixed
- Hotfix for CSV export encoding issue (#134)

[1.3.0]: https://github.com/user/repo/compare/v1.2.3...v1.3.0
[1.2.3]: https://github.com/user/repo/compare/v1.2.2...v1.2.3
```

### Rules
- Newest version at the top
- Dates in ISO 8601 format (YYYY-MM-DD)
- `[Unreleased]` section for unreleased changes
- Only include sections that have entries (don't show empty "Deprecated" section)
- Link versions to compare URLs at the bottom
- Human-readable descriptions, not raw commit messages
- Group related changes into single entries

### Section Mapping from Commit Types
| Commit Type | Changelog Section |
|-------------|------------------|
| feat | Added |
| fix | Fixed |
| perf | Changed |
| refactor | Changed |
| docs | Changed (if user-facing) or omit |
| BREAKING CHANGE | Changed + call out prominently |
| deprecated | Deprecated |
| removed/deleted | Removed |
| security | Security |
| chore, ci, build, test, style | Usually omit unless user-facing |

---

## GitHub Release Notes Format

Richer format for GitHub release pages. Supports full markdown including images, details blocks, and mentions.

### Template
```markdown
## Highlights

Brief 2-3 sentence summary of the most important changes in this release.

## What's New

### ✨ Features
- **User Profile Settings** — Edit your profile name, avatar, and notification preferences. (#142)
- **Dark Mode** — Toggle between light and dark themes. Your preference is saved automatically. (#138)

### 🐛 Bug Fixes
- Fixed login redirect loop on Safari when using SSO (#141)
- Date picker now correctly handles non-UTC timezones (#136)

### ⚡ Performance
- Dashboard loads 40% faster thanks to lazy-loaded chart components (#137)

### 💥 Breaking Changes
- `legacyAuth()` has been removed. Use `authenticate()` instead. See [migration guide](#migration).

## Migration Guide

If you're upgrading from v1.2.x:

1. Replace all calls to `legacyAuth()` with `authenticate()`
2. Update your auth config — see [docs](link)

## Contributors

Thanks to the following people for their contributions:
- @username1 — profile settings, dark mode
- @username2 — Safari fix, timezone fix
- @username3 — performance improvements

**Full Changelog**: https://github.com/user/repo/compare/v1.2.3...v1.3.0
```

### Best Practices
- Lead with a **Highlights** section (what should users care about?)
- Use bold for feature names in the list
- Include PR/issue numbers as links
- Add a migration guide for any breaking changes
- Credit contributors with GitHub @mentions
- Include a "Full Changelog" compare link at the bottom
- Use `<details>` blocks for long lists:
  ```markdown
  <details>
  <summary>All 15 bug fixes</summary>

  - Fix 1
  - Fix 2
  ...
  </details>
  ```

---

## Conventional Changelog Format

Auto-generated format used by tools like `conventional-changelog` and `standard-version`.

### Template
```markdown
# [1.3.0](https://github.com/user/repo/compare/v1.2.3...v1.3.0) (2026-03-13)

### Features

* **auth:** add SSO login support ([#142](https://github.com/user/repo/issues/142)) ([abc1234](https://github.com/user/repo/commit/abc1234))
* **ui:** implement dark mode toggle ([#138](https://github.com/user/repo/issues/138)) ([def5678](https://github.com/user/repo/commit/def5678))

### Bug Fixes

* **auth:** resolve redirect loop on Safari ([#141](https://github.com/user/repo/issues/141)) ([ghi9012](https://github.com/user/repo/commit/ghi9012))

### BREAKING CHANGES

* **auth:** `legacyAuth()` has been removed
```

This format is more technical and less human-friendly. Use it only if the project already uses this style.

---

## Writing Good Changelog Entries

### Do
- Write for end users, not developers
- Describe the impact: "Export now supports CSV format" not "add CSV serializer to export module"
- Group related commits: 3 commits that implement dark mode → one "Dark mode" entry
- Include PR/issue numbers for traceability
- Call out breaking changes prominently

### Don't
- Don't just copy commit messages verbatim
- Don't include internal refactoring unless it affects users
- Don't include CI/CD changes unless they affect the release process
- Don't include "merge branch" or "fix typo in comment" noise
- Don't use technical jargon when a simpler description exists
