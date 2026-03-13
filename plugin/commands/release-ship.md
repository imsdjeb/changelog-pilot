---
description: "Full release pipeline in one command — preview, changelog, bump, commit, tag, and GitHub release."
argument-hint: "[major|minor|patch] e.g. minor"
---

Run the **SHIP** workflow from the changelog-pilot skill. Execute the full release pipeline sequentially with confirmation between steps: preview → changelog → bump → commit → tag → GitHub release notes.

If a bump type is provided, use it. Otherwise, use the recommended bump from commit analysis.
