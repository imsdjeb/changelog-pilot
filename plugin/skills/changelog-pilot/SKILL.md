---
name: changelog-pilot
description: "Full release orchestrator. Use this skill whenever the user mentions: releasing a new version, generating a changelog, bumping the version, creating a release, tagging a version, writing release notes, preparing a release, publishing a release, shipping a new version, semver, version bump, what changed since last release, conventional commits analysis, or anything related to the release/versioning lifecycle. Also triggers on /changelog-pilot:* commands."
---

# changelog-pilot

Full release orchestrator: changelog, version bump, tag, GitHub release notes.

Before any workflow, run the detection scripts from `skills/changelog-pilot/scripts/`:
- `detect-commits.sh` — finds last tag, lists commits, detects commit style
- `detect-version.sh` — finds current version across all manifest files

Load reference docs from `skills/changelog-pilot/references/` as needed.

The plugin supports 3 commit styles:
- **Conventional Commits**: `feat:`, `fix:`, `chore:`, etc. + `BREAKING CHANGE:`
- **Gitmoji**: ✨, 🐛, 🔥, etc. (mapped to conventional types)
- **Freeform**: no convention — categorized by semantic keyword analysis

## Config: .changelog-pilot.json (optional)

```json
{
  "commitStyle": "auto",
  "changelogFile": "CHANGELOG.md",
  "changelogFormat": "keepachangelog",
  "versionFiles": ["package.json"],
  "tagPrefix": "v",
  "githubRelease": true,
  "groupMergeCommits": true,
  "excludeScopes": ["deps", "ci"],
  "contributors": true,
  "preReleaseTag": null
}
```

All fields optional. Auto-detection by default.

---

## Workflow 1: PREVIEW

**Trigger:** `/changelog-pilot:preview` or user asks what changed since last release.

Steps:

1. Run `detect-commits.sh` to find last tag and list all commits since.
2. Parse each commit based on the detected style:
   - **Conventional Commits** → extract type, scope, description, body, BREAKING CHANGE footer
   - **Gitmoji** → map emoji to type (see `references/conventional-commits.md` for the mapping table)
   - **Freeform** → analyze keywords: "add/implement/introduce" → feat, "fix/resolve/patch" → fix, "remove/delete/drop" → removed, "update/change/modify" → changed, "refactor/clean/restructure" → maintenance, "break/incompatible" → breaking
3. Group by category:
   - 🚀 **Features** (feat, ✨)
   - 🐛 **Bug Fixes** (fix, 🐛)
   - 💥 **Breaking Changes** (BREAKING CHANGE, 💥)
   - ⚡ **Performance** (perf, ⚡)
   - 📖 **Documentation** (docs, 📝)
   - 🔧 **Maintenance** (chore, refactor, ci, build, style, test)
4. Calculate recommended version bump (see `references/versioning-rules.md`):
   - **Major**: at least one BREAKING CHANGE
   - **Minor**: at least one feat, no breaking changes
   - **Patch**: only fix/chore/docs/refactor
5. Extract PR numbers from commit messages (patterns: `(#123)`, `Closes #123`, `Refs #123`)
6. Extract contributor names from `git log --format="%an"`

Output format:
```
📋 Release Preview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Current: v{current}
🎯 Next:    v{next} ({bump_type} — {reason})
📊 {count} commits since v{current}

🚀 Features ({count})
   • {description} (#{pr})
   ...

🐛 Bug Fixes ({count})
   • {description} (#{pr})
   ...

🔧 Maintenance ({count})
   ...

💥 Breaking Changes: {list or "None"}
```

---

## Workflow 2: CHANGELOG

**Trigger:** `/changelog-pilot:changelog [version]` or user asks to generate/update the changelog.

Steps:

1. Run PREVIEW internally if not already done.
2. Generate a **human-readable** changelog entry:
   - Don't just copy commit messages — rewrite them for end users
   - Group related commits: 3 commits touching the same feature → one entry
   - Focus on user impact, not implementation details ("Improved login reliability" not "refactor auth module")
   - Include PR numbers and author names when available
3. Use **Keep a Changelog** format (see `references/changelog-formats.md`):
   - Sections: Added, Changed, Deprecated, Removed, Fixed, Security
   - Only include sections that have entries
   - Date in ISO format (YYYY-MM-DD)
4. Show the generated entry and ask the user:
   - Insert at the top of existing CHANGELOG.md? (or create it if absent)
   - Adjust any wording?
5. Apply after confirmation.

The goal: a changelog that someone can read in 30 seconds and understand what changed, without looking at the git log.

---

## Workflow 3: BUMP

**Trigger:** `/changelog-pilot:bump [major|minor|patch|version-number]` or user asks to bump the version.

Steps:

1. Calculate the recommended bump based on commits (or use the user's override).
2. Show the recommendation and ask for confirmation.
3. Run `detect-version.sh` to find all files containing version numbers.
4. Update the version in ALL relevant files:
   - `package.json` + `package-lock.json`
   - `pubspec.yaml`
   - `Cargo.toml`
   - `pyproject.toml` / `setup.py` / `setup.cfg`
   - `version.rb` / `*.gemspec`
   - `*.csproj` / `Directory.Build.props`
   - Any custom file listed in config `versionFiles`
5. Update CHANGELOG.md: replace `[Unreleased]` with `[{version}] - {date}` if applicable.
6. Commit: `chore(release): bump version to {version}`

---

## Workflow 4: TAG

**Trigger:** `/changelog-pilot:tag [version]` or user asks to tag the release.

Steps:

1. Verify the working directory is clean (`git status --porcelain`). If not, warn the user.
2. Determine the version from the argument, or from the latest version in manifest files.
3. Check that a tag with this version doesn't already exist.
4. Create an annotated tag: `git tag -a {prefix}{version} -m "Release {prefix}{version}"`
5. Offer to push the tag: `git push origin {prefix}{version}`

The `tagPrefix` defaults to `v` (e.g., `v1.3.0`), configurable in `.changelog-pilot.json`.

---

## Workflow 5: NOTES

**Trigger:** `/changelog-pilot:notes [version]` or user asks to create GitHub release / publish release notes.

Steps:

1. Get the changelog content for this version (from CHANGELOG.md or generate it).
2. Enrich for GitHub release format:
   - **Executive summary** at the top: 2-3 sentences highlighting the most important changes
   - **Full changelog** from CHANGELOG.md
   - **Contributors** section with `@username` mentions (map author names to GitHub usernames via `git log --format="%an|%ae"` and GitHub API)
   - **Upgrade Guide** if there are breaking changes
3. Create the GitHub release:
   - Try `gh release create {tag} --title "v{version}" --notes "{notes}"` if gh CLI is available
   - Otherwise, use the GitHub API via MCP
4. Mark as pre-release if version contains alpha/beta/rc tag.
5. Output the release URL.

---

## Workflow 6: SHIP

**Trigger:** `/changelog-pilot:ship [major|minor|patch]` or user says "ship it", "full release".

This is the all-in-one workflow. Executes sequentially with confirmation between steps:

1. **PREVIEW** — Show what changed, proposed version
2. **Confirm** — Ask user to approve version number and changelog
3. **CHANGELOG** — Write to CHANGELOG.md
4. **BUMP** — Update version in all manifest files
5. **Commit** — `chore(release): v{version}`
6. **TAG** — Create and push annotated tag
7. **NOTES** — Publish GitHub release

```
🚢 Shipping v{version}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 1/7: ✅ Preview (N commits analyzed)
Step 2/7: ✅ Confirmed by user
Step 3/7: ✅ Changelog written
Step 4/7: ✅ Version bumped in {files}
Step 5/7: ✅ Committed
Step 6/7: ✅ Tag {tag} created and pushed
Step 7/7: ✅ GitHub release published

🎉 v{version} is live! {release_url}
```

---

## Important Rules

1. **Never auto-release without confirmation.** Every destructive action (commit, tag, push, publish) requires user approval.
2. **Never modify git history.** No rebase, no amend, no force push.
3. **Respect existing changelog format.** If the project already has a CHANGELOG.md with a specific style, match it.
4. **Handle missing tags gracefully.** If no tags exist, use the first commit as the baseline and mention it.
5. **Handle monorepos.** If the project has multiple packages, ask which one to release (or detect from cwd).
6. **Pre-release versions.** Understand and handle `-alpha.1`, `-beta.2`, `-rc.1` suffixes per SemVer spec.
7. **Idempotency.** Running the same workflow twice should not produce duplicate entries or errors.
