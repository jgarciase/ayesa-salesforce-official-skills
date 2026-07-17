# Update official Salesforce skills in this plugin from upstream.

Run the sync script from the repository root:

```powershell
npm run sync:skills
```

Or with PowerShell directly:

```powershell
.\scripts\sync-skills.ps1
```

## Options

| Flag / script | Purpose |
| --- | --- |
| `-Ref <tag\|branch\|commit>` | Pin upstream version (default: `main`) |
| `-Force` / `npm run sync:skills:force` | Re-clone vendor cache from scratch |
| `npm run sync:skills -- -Ref 1.30.0` | Sync a specific upstream tag |

After syncing, reload Cursor (**Developer: Reload Window**) or re-import the plugin in the team marketplace so agents pick up the new skills.
