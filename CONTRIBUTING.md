# Contributing to changelog-pilot

Glad you're here. Here's how you can help.

## Ways to Contribute

### Add a Changelog Format

If you use a changelog format that isn't covered:

1. Document it in `plugin/skills/changelog-pilot/references/changelog-formats.md`
2. Include a full template with examples
3. Describe when to use it vs the existing formats

### Support a New Version File

If your ecosystem stores versions in a file we don't detect:

1. Add detection logic to `plugin/skills/changelog-pilot/scripts/detect-version.sh`
2. Document the ecosystem's versioning conventions in `references/versioning-rules.md`
3. Include the bump command if one exists

### Improve Commit Parsing

The freeform commit classifier can always be smarter:

1. Add keyword patterns to the freeform classification section in `references/conventional-commits.md`
2. If you spot misclassifications, open an issue with the commit message and expected category

### Add Gitmoji Mappings

If we're missing a gitmoji mapping:

1. Add it to the mapping table in `references/conventional-commits.md`
2. Include the emoji, shortcode, conventional type, and description

## Pull Request Guidelines

- One improvement per PR
- Include real examples from actual projects when possible
- Update CHANGELOG.md with your changes (yes, we dogfood)

## Questions?

Open an issue.
