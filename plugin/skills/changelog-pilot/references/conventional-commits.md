# Conventional Commits Reference

## Spec (v1.0.0)

Format:
```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

## Types and Semver Mapping

| Type | Description | Semver Impact |
|------|-------------|---------------|
| `feat` | A new feature | **minor** |
| `fix` | A bug fix | **patch** |
| `docs` | Documentation only | **patch** (or none) |
| `style` | Formatting, semicolons, whitespace (no code change) | **patch** |
| `refactor` | Code change that neither fixes a bug nor adds a feature | **patch** |
| `perf` | Performance improvement | **patch** |
| `test` | Adding or fixing tests | **patch** (or none) |
| `ci` | CI/CD configuration changes | **patch** (or none) |
| `build` | Build system or external dependency changes | **patch** |
| `chore` | Other changes that don't modify src or test | **patch** (or none) |
| `revert` | Reverts a previous commit | depends on reverted type |

**BREAKING CHANGE** in footer or `!` after type → **major**

## Scope

Optional context in parentheses:
```
feat(auth): add SSO login
fix(dashboard): resolve chart rendering bug
refactor(api): simplify error handling
```

Common scopes: `auth`, `api`, `ui`, `db`, `config`, `deps`, `core`, `router`, `store`, `i18n`, `ssr`, `a11y`

## Footers

```
BREAKING CHANGE: description of what breaks
Closes #123
Refs #456
Co-authored-by: Name <email>
Reviewed-by: Name <email>
```

`BREAKING CHANGE:` must be uppercase. Can also use `BREAKING-CHANGE:`.

## Examples

```
feat: add user profile settings page

Adds the ability to edit profile name, avatar, and notification preferences.

Closes #142
```

```
fix(auth): resolve redirect loop on Safari

Safari's ITP was blocking the session cookie on redirect, causing an
infinite login loop. Switched to SameSite=None with Secure flag.

Closes #141
```

```
feat(export)!: change CSV export format

BREAKING CHANGE: CSV export now uses semicolons as delimiter instead of
commas. This affects all integrations consuming the exported files.
```

```
chore(deps): upgrade dependencies

Updated axios to 1.6.0, react-query to 5.0.0
```

---

## Gitmoji → Conventional Commits Mapping

| Gitmoji | Code | Conventional Type | Description |
|---------|------|-------------------|-------------|
| ✨ | `:sparkles:` | feat | New feature |
| 🐛 | `:bug:` | fix | Bug fix |
| 🔥 | `:fire:` | refactor | Remove code/files |
| 📝 | `:memo:` | docs | Documentation |
| 🚀 | `:rocket:` | perf | Performance |
| 💄 | `:lipstick:` | style | UI/style changes |
| 🎉 | `:tada:` | feat | Initial commit / big feature |
| ✅ | `:white_check_mark:` | test | Add/update tests |
| 🔒 | `:lock:` | fix | Security fix |
| 🔖 | `:bookmark:` | chore | Release/version tag |
| 🚨 | `:rotating_light:` | style | Fix linter warnings |
| 🚧 | `:construction:` | feat | Work in progress |
| 💚 | `:green_heart:` | ci | Fix CI build |
| ⬇️ | `:arrow_down:` | build | Downgrade dependency |
| ⬆️ | `:arrow_up:` | build | Upgrade dependency |
| 📌 | `:pushpin:` | build | Pin dependency |
| 👷 | `:construction_worker:` | ci | CI changes |
| 📈 | `:chart_with_upwards_trend:` | feat | Analytics/tracking |
| ♻️ | `:recycle:` | refactor | Refactor code |
| ➕ | `:heavy_plus_sign:` | build | Add dependency |
| ➖ | `:heavy_minus_sign:` | build | Remove dependency |
| 🔧 | `:wrench:` | chore | Config changes |
| 🌐 | `:globe_with_meridians:` | feat | i18n/l10n |
| ✏️ | `:pencil2:` | fix | Fix typo |
| 💩 | `:hankey:` | chore | Bad code (needs improvement) |
| ⏪ | `:rewind:` | revert | Revert changes |
| 🔀 | `:twisted_rightwards_arrows:` | chore | Merge branches |
| 🗃️ | `:card_file_box:` | feat | Database changes |
| 💥 | `:boom:` | feat (BREAKING) | Breaking change |
| 🍱 | `:bento:` | feat | Add/update assets |
| ♿ | `:wheelchair:` | feat | Accessibility |
| 🏗️ | `:building_construction:` | refactor | Architectural changes |
| 📱 | `:iphone:` | feat | Responsive design |
| 🤡 | `:clown_face:` | test | Mock data |
| 🥅 | `:goal_net:` | fix | Error handling |
| 🗑️ | `:wastebasket:` | refactor | Deprecate code |

---

## Freeform Commit Classification

When commits don't follow any convention, classify by keyword analysis:

### → feat (feature)
Keywords: `add`, `implement`, `introduce`, `create`, `new`, `support`, `enable`, `allow`

### → fix (bug fix)
Keywords: `fix`, `resolve`, `patch`, `correct`, `repair`, `handle`, `address`, `workaround`

### → refactor
Keywords: `refactor`, `restructure`, `reorganize`, `simplify`, `clean`, `extract`, `move`, `rename`

### → docs
Keywords: `document`, `readme`, `comment`, `jsdoc`, `docstring`, `wiki`, `guide`

### → perf
Keywords: `optimize`, `performance`, `speed`, `cache`, `lazy`, `faster`, `reduce`

### → build/deps
Keywords: `upgrade`, `downgrade`, `bump`, `dependency`, `deps`, `update.*package`, `migrate.*lib`

### → ci
Keywords: `ci`, `pipeline`, `workflow`, `github action`, `deploy`, `docker`, `jenkins`

### → breaking
Keywords: `break`, `incompatible`, `remove.*support`, `drop.*support`, `deprecate`, `migration required`

### → chore (fallback)
Anything that doesn't match the above patterns.

### Confidence
- 2+ keyword matches in the same category → high confidence
- 1 keyword match → medium confidence (use it but flag uncertainty)
- 0 matches → chore (default)
