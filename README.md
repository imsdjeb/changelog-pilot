# 🚀 changelog-pilot

**Ship releases, not stress.**

Preview changes → Generate changelog → Bump version → Tag → Publish GitHub release. One command or six — your call.

---

## Why changelog-pilot?

Every release is the same cycle: scroll through commits, figure out what's a feature vs a fix, write a changelog, decide if it's a major or minor, update the version in 3 different files, create the tag, write release notes, publish on GitHub. It's tedious, error-prone, and always takes longer than expected.

I built changelog-pilot to handle the entire release lifecycle from my terminal. It reads my commits, understands what changed, writes a changelog that humans actually want to read, bumps the version everywhere, and publishes the release. I can do everything in one command or step by step — whatever the situation calls for.

---

## Install

```bash
# Add the marketplace (one-time)
claude plugin marketplace add imsdjeb/changelog-pilot

# Install the plugin
claude plugin install changelog-pilot@imsdjeb-changelog-pilot
```

---

## Commands

| Command | What it does |
|---------|-------------|
| `/changelog-pilot:preview` | Preview changes since last release — categorized commits + recommended bump |
| `/changelog-pilot:changelog` | Generate a human-readable changelog entry |
| `/changelog-pilot:bump` | Bump version in all manifest files |
| `/changelog-pilot:tag` | Create annotated git tag + push |
| `/changelog-pilot:notes` | Publish GitHub release with highlights and contributor credits |
| `/changelog-pilot:ship` | Full pipeline — all of the above in sequence |

---

## Quick Start

### One command

```
/changelog-pilot:ship
```

That's it. Preview → Changelog → Bump → Commit → Tag → GitHub Release. Asks for confirmation at each step.

### Step by step

```
/changelog-pilot:preview     # See what changed, get recommended bump
/changelog-pilot:changelog   # Write the changelog entry
/changelog-pilot:bump minor  # Bump version in all files
/changelog-pilot:tag         # Create + push the git tag
/changelog-pilot:notes       # Publish GitHub release
```

---

## Commit Styles

changelog-pilot understands how you write commits — no need to change your habits.

**Conventional Commits** — `feat:`, `fix:`, `chore:`, `BREAKING CHANGE:`, etc. Parsed precisely per the spec.

**Gitmoji** — ✨ `:sparkles:`, 🐛 `:bug:`, 💥 `:boom:`, etc. Mapped to conventional types automatically.

**Freeform** — No convention? No problem. The plugin analyzes commit messages semantically: "Add dark mode" → feature, "Fix login bug" → fix, "Update dependencies" → maintenance. It's not perfect, but it's surprisingly good.

The style is auto-detected from your recent commits. You can override it in the config.

---

## Smart Changelog

The changelog isn't a commit dump. It's written for humans:

- **Groups related commits** — 3 commits that implement the same feature become one entry
- **Rewrites for clarity** — "refactor auth module to use strategy pattern" becomes "Improved login reliability"
- **Includes PR numbers** — for traceability
- **Credits contributors** — in GitHub release notes
- **Adds upgrade guides** — when there are breaking changes

Uses the [Keep a Changelog](https://keepachangelog.com/) format by default: Added, Changed, Fixed, Removed, Security.

---

## Works Everywhere

changelog-pilot is language and framework agnostic. It finds your version in:

| File | Ecosystem |
|------|-----------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `pubspec.yaml` | Flutter / Dart |
| `Cargo.toml` | Rust |
| `pyproject.toml` / `setup.py` / `setup.cfg` | Python |
| `*.gemspec` / `version.rb` | Ruby |
| `*.csproj` / `Directory.Build.props` | .NET |
| Git tags | Go (and anything else) |

When bumping, it updates **all** files that contain the version — not just one.

---

## Natural Language

You don't need slash commands:

- *"What changed since the last release?"*
- *"Ship a new version"*
- *"Generate the changelog"*
- *"Bump to 2.0.0"*
- *"Create a GitHub release"*
- *"We need a patch release for this bugfix"*
- *"Prepare a beta release"*

---

## Configuration (Optional)

Create `.changelog-pilot.json` at your project root:

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

All fields optional. The defaults work for most projects. Notable options:

- **`commitStyle`**: `"auto"`, `"conventional"`, `"gitmoji"`, or `"freeform"`
- **`excludeScopes`**: commit scopes to exclude from the changelog (e.g., `deps`, `ci`)
- **`groupMergeCommits`**: collapse merge commits into their component commits
- **`preReleaseTag`**: set to `"alpha"`, `"beta"`, or `"rc"` for pre-release versions

---

## How It Works

```
detect-commits.sh ──→ PREVIEW ──→ CHANGELOG ──→ BUMP ──→ TAG ──→ NOTES
       │                  │            │           │         │        │
       │                  │            │           │         │        └─ gh release create
       │                  │            │           │         └─ git tag -a
       │                  │            │           └─ update all manifest files
       │                  │            └─ write CHANGELOG.md
       │                  └─ categorize + recommend bump
       └─ find last tag, list commits, detect style
```

Detection scripts run first to gather raw data. Each workflow builds on the previous one. The SHIP command chains them all with confirmation gates.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding changelog formats, supporting new version file types, and improving commit parsing.

---

## License

[MIT](LICENSE)
