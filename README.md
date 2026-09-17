# Salesforce Official Skills — Cursor Plugin

Cursor plugin that bundles the **official Salesforce agent skills** from [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills). Skills cover Apex, LWC, Flow, metadata deploy/retrieve, Agentforce, Data Cloud, OmniStudio, Experience Cloud, integrations, and more.

This repository is a **thin distribution layer**: skills are synced from upstream on demand and committed here so teams can install them as a Cursor plugin without running `npx skills add` in every project.

> Upstream skills evolve quickly and may be renamed or restructured between releases. See [skills-lock.json](skills-lock.json) for the exact commit and version currently bundled.

---

## What is included

| Component | Path | Description |
| --- | --- | --- |
| Plugin manifest | [`.cursor-plugin/plugin.json`](.cursor-plugin/plugin.json) | Cursor plugin metadata and skill paths |
| Team marketplace | [`.cursor-plugin/marketplace.json`](.cursor-plugin/marketplace.json) | Required for Cursor Teams import |
| Skills | [`.cursor/skills/`](.cursor/skills/) | Synced from upstream `skills/` (see `skills-lock.json` for count) |
| Sync lock | [`skills-lock.json`](skills-lock.json) | Upstream ref, commit, version, skill list |

---

## Install

### Team marketplace (recommended)

1. In the **Cursor dashboard**, go to **Settings → Plugins → Import**.
2. Paste: `https://github.com/jgarciase/ayesa-salesforce-official-skills`
3. For private repos, grant the **Cursor GitHub App** read access.
4. Mark the plugin **Required** or **Optional** for your groups.
5. Wait for re-indexing (may take a few minutes).

Both manifest files must exist on the default branch:

- `.cursor-plugin/marketplace.json` — what the dashboard imports
- `.cursor-plugin/plugin.json` — component paths (skills only)

### Local testing

Copy or symlink this repo to:

```text
~/.cursor/plugins/local/ayesa-salesforce-official-skills/
```

Then **Developer: Reload Window** and verify skills under **Customize**.

---

## Update skills from upstream (maintainers only)

> **Admin workflow.** This is not exposed to plugin users. Run it from this repository to pull upstream changes, then commit and push.

Requires **git** and **PowerShell 5.1+** (Windows) or PowerShell Core (macOS/Linux).

```powershell
npm run sync:skills
```

Or directly:

```powershell
.\scripts\sync-skills.ps1
```

### Options

| Command | Purpose |
| --- | --- |
| `npm run sync:skills` | Sync latest `main` from forcedotcom/sf-skills |
| `npm run sync:skills:force` | Delete vendor cache and re-clone |
| `.\scripts\sync-skills.ps1 -Ref 1.30.0` | Pin a specific upstream tag |
| `.\scripts\sync-skills.ps1 -Ref <commit>` | Pin a specific commit |

The script:

1. Sparse-clones only `skills/` (avoids Windows path-length issues with upstream `samples/`).
2. Mirrors into `.cursor/skills/` (removes skills deleted upstream).
3. Updates `skills-lock.json` and plugin version in both manifest files.

After syncing, commit the changes and reload Cursor (or re-import in the team marketplace).

---

## Repository layout

```text
.
├── .cursor/
│   └── skills/            # Synced official Salesforce skills (do not edit manually)
├── .cursor-plugin/
│   ├── plugin.json        # Plugin manifest
│   └── marketplace.json   # Team marketplace registry
├── scripts/
│   └── sync-skills.ps1    # Upstream sync script
├── skills-lock.json       # Sync provenance
├── package.json           # npm scripts wrapper
└── README.md
```

---

## License

Skills content is sourced from [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills) (upstream license: **CC-BY-NC-4.0**). This wrapper repository follows the same upstream terms for synced skill content.

---

## Related links

- Upstream: [forcedotcom/sf-skills](https://github.com/forcedotcom/sf-skills)
- Agent Skills spec: [agentskills.io](https://agentskills.io/)
- Cursor plugins docs: [cursor.com/docs/plugins](https://cursor.com/docs/plugins)
