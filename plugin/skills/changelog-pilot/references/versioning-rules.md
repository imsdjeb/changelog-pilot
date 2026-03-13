# Versioning Rules Reference

## SemVer 2.0.0 Summary

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: incompatible API changes (breaking changes)
- **MINOR**: new functionality in a backward-compatible manner
- **PATCH**: backward-compatible bug fixes

## Version Bump Decision Tree

```
Has any commit with BREAKING CHANGE or ! after type?
  → YES → MAJOR bump
  → NO  → Has any commit with type "feat" or new feature?
            → YES → MINOR bump
            → NO  → PATCH bump
```

### Special Cases
- Multiple features + fixes → MINOR (features dominate)
- Only docs/chore/ci/test → PATCH (or skip release entirely)
- Revert of a feature → depends on whether it was released; if yes, MINOR (removing a feature is adding the absence of it)
- Performance improvements without API change → PATCH

## Pre-release Versions

Format: `MAJOR.MINOR.PATCH-<pre-release>`

### Identifiers
| Tag | Meaning | Example | Ordering |
|-----|---------|---------|----------|
| `alpha` | Early testing, unstable | `2.0.0-alpha.1` | lowest |
| `beta` | Feature-complete, testing | `2.0.0-beta.1` | middle |
| `rc` | Release candidate, final testing | `2.0.0-rc.1` | highest pre-release |

### Ordering Rules
```
1.0.0-alpha.1 < 1.0.0-alpha.2 < 1.0.0-beta.1 < 1.0.0-rc.1 < 1.0.0
```

Pre-release versions:
- Have lower precedence than the associated normal version
- Should NOT be installed by default by package managers
- Are incremented independently: `alpha.1` → `alpha.2` → `beta.1`

### When to Use
- `alpha`: internal testing, API may change significantly
- `beta`: external testing, API mostly stable, bugs expected
- `rc`: final validation before release, only critical fixes allowed

## Build Metadata

Format: `MAJOR.MINOR.PATCH+<build>`

Example: `1.0.0+20260313`, `1.0.0+build.123`

Build metadata is **ignored** for version precedence:
```
1.0.0+build.1 == 1.0.0+build.2  (same precedence)
```

Use for: CI build numbers, timestamps, git SHAs. Never for release differentiation.

## Version 0.x.y Rules

During initial development (`0.x.y`):
- **Anything may change at any time.** The public API is not stable.
- `0.1.0` → `0.2.0`: may contain breaking changes (treated as minor but breaking is OK)
- `0.x.y` → `1.0.0`: signals that the public API is stable

In practice:
- Most projects treat `0.MINOR` bumps as "may break" and `0.x.PATCH` as "shouldn't break"
- Don't stay at 0.x forever — if it's in production, it should be 1.0

## Ecosystem-Specific Version Bumping

### npm (package.json)
```bash
npm version patch    # 1.2.3 → 1.2.4
npm version minor    # 1.2.3 → 1.3.0
npm version major    # 1.2.3 → 2.0.0
npm version 1.5.0    # explicit version
npm version prerelease --preid=alpha  # 1.2.3 → 1.2.4-alpha.0
```
- Also updates `package-lock.json`
- Creates a git commit and tag by default (use `--no-git-tag-version` to skip)

### Dart/Flutter (pubspec.yaml)
```yaml
version: 1.2.3+4  # version + build number (Android/iOS)
```
- Build number (`+N`) is independent of semver
- Increment build number with every release, even patches
- No built-in CLI for bumping — edit manually or use `cider`

### Rust (Cargo.toml)
```bash
cargo set-version 1.3.0  # via cargo-edit
```
- `Cargo.lock` auto-updates on build
- Workspace members may have independent versions

### Python (pyproject.toml / setup.py / setup.cfg)
```bash
# With bump2version
bump2version patch  # 1.2.3 → 1.2.4
# With hatch
hatch version minor # 1.2.3 → 1.3.0
# With poetry
poetry version patch
```
- Multiple possible version locations — check all of them
- `__version__` in `__init__.py` is also common

### Ruby (*.gemspec / version.rb)
```bash
# With gem-release
gem bump --version minor
```
- Version often in `lib/{gem_name}/version.rb`
- Referenced from `.gemspec`

### .NET (*.csproj)
```xml
<PropertyGroup>
  <Version>1.2.3</Version>
</PropertyGroup>
```
- Can also be in `Directory.Build.props` for solution-wide version
- `dotnet` CLI doesn't have a built-in version bump command

### Go
- Go modules use git tags for versioning, not a manifest file
- Tag format: `v1.2.3`
- Major versions 2+ require a `/v2` path suffix in `go.mod`:
  ```
  module github.com/user/repo/v2
  ```

## Monorepo Strategies

### Independent Versioning
Each package has its own version. Used by: Lerna (independent mode), Changesets, Turborepo.
- Pro: packages evolve independently
- Con: complex dependency management
- Tagging: `@package/name@1.2.3`

### Fixed/Locked Versioning
All packages share the same version. Used by: Angular, Babel.
- Pro: simpler mental model
- Con: meaningless bumps for unchanged packages
- Tagging: `v1.2.3`

## Hotfix Strategy

For patches on older major/minor versions while main has moved forward:

```
main:     v1.3.0 ──── v1.4.0 ──── v1.5.0
                 \
hotfix:           └── v1.3.1 ──── v1.3.2
```

1. Create a branch from the release tag: `git checkout -b hotfix/1.3.x v1.3.0`
2. Apply the fix
3. Bump patch: `1.3.0` → `1.3.1`
4. Tag and release
5. Cherry-pick the fix to main if applicable
