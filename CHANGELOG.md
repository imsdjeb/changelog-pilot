# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-03-13

### Added

- **PREVIEW workflow** — Analyze commits since last tag, categorize by type, recommend semver bump
- **CHANGELOG workflow** — Generate human-readable changelog entries in Keep a Changelog format
- **BUMP workflow** — Update version across all manifest files (package.json, pubspec.yaml, Cargo.toml, pyproject.toml, gemspec, csproj)
- **TAG workflow** — Create annotated git tags with push option
- **NOTES workflow** — Publish GitHub releases with highlights, contributor credits, and upgrade guides
- **SHIP workflow** — Full release pipeline in one command with confirmation gates
- **Commit detection script** — Auto-detect last tag, list commits, identify commit style
- **Version detection script** — Find current version across 10+ manifest file types
- **Three commit style support** — Conventional Commits, Gitmoji, and freeform (keyword-based classification)
- **Conventional Commits reference** — Full spec, type mapping, gitmoji table, freeform keywords
- **Changelog formats reference** — Keep a Changelog, GitHub Releases, Conventional Changelog templates
- **Versioning rules reference** — SemVer 2.0.0, pre-release, build metadata, ecosystem-specific bumping, monorepo strategies
- **Post-edit hook** — Suggests verification when CHANGELOG.md is manually modified
