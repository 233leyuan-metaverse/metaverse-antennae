---
name: buildmode-editor
description: Initialize a UGC project with the packaged Buildmode CLI knowledge, then inspect, modify, diagnose, and verify content through the sideapi_bridge MCP semantic tools. Use for Buildmode editor work, UGC project bootstrap, CLI version compatibility, and exact post-write readback.
---

# Buildmode Editor

Operate the live editor through named semantic tools. Treat tool schemas, lookup results, and live inspect results as authoritative. Never invent object IDs, resource IDs, property paths, event paths, ability IDs, or Blockly shapes.

## Automatic UGC project bootstrap

The MCP resolves the active project through the editor-local bridge and silently synchronizes its packaged CLI payload after every WebSocket connection. Do not ask the user for a project path or call project-install tools.

Use `status` only when bootstrap diagnostics are needed and inspect `response.projectInitialization`:

- `ok=true`: continue with project work.
- `ok=false`: stop project-dependent work and report the structured error. Automatic downgrade remains blocked. For `UGC_CLI_DOWNGRADE_BLOCKED`, first show the exact editor-reported `projectDir`, `installedVersion`, `packagedVersion`, and the impact of rolling project-local CLI knowledge back. Only after the user explicitly approves that downgrade, call `project_cli_confirm_downgrade` with those exact three values and `confirmation=CONFIRM_PROJECT_CLI_DOWNGRADE`. Do not use caller-invented paths or versions and do not call the tool for upgrades, missing installs, or ordinary reconnects.
- After `project_cli_confirm_downgrade`, require `outcome=succeeded_verified`, `response.relation=match`, exact packaged/installed versions, equal positive `filesCopied`/`filesVerified`, and `skillActivation.referencesVerified=true`. Then use `status` to require the same `projectInitialization` readback. If `newSessionRequired=true`, stop project work and tell the user to start a new task so the downgraded project Skills load.
- `skillActivation.referencesVerified=false`, `skillActivation.newSessionRequired=true`, or the current agent cannot access the project-root `AGENTS.md` and installed domain Skills: tell the user to open `projectDir` as the current project/workspace and start a new task or session so the host reloads the project instructions. Optional host-specific Skill references never block editor tools. This is an agent guidance check only; the MCP does not inspect, compare, or enforce client workspace roots.

When those project instructions are available, follow project-root `AGENTS.md` and its domain Skills. Project files own planning and API discovery; the MCP owns editor connectivity, automatic CLI synchronization, and semantic operations.

## Core workflow

1. Discover the current state with `inspect`; use `status` only for explicit connection diagnostics.
2. For **new scene / terrain / architecture / environment** builds: skip resource lookup and call `three_scene_run` with full ThreeCompat JS. For edits to existing content, resolve real object / widget / canvas / preset IDs before writing.
3. Select a named semantic tool from its exposed description and input schema.
4. For gameplay or multi-step work, use the named semantic tools and their exposed schemas directly. For an ordinary fixed-point spawner, prefer the named `mechanism_create_spawner` tool over manually composing carrier creation and ability slots. For new scene geometry or layout, use the installed `three-scene` Skill, then make one `three_scene_run` call with the full ThreeCompat JavaScript; use asset-library props only as post-scene decoration. Batch only for early user-visible progress, with `clearPrevious=false` on later calls.
5. Execute the smallest valid write.
6. Read back the exact affected values, bindings, workspace, or object details before reporting completion.

Read [tool-routing.md](references/tool-routing.md) when selecting tools for a multi-domain task. Read [verification.md](references/verification.md) before any write or repair.

## Source-scanned Ability property overlay

When an Ability property is missing from, or has stale typing in, the live Contract, call `ability_overlay_catalog` with the exact Ability or canonical property path. The catalog intersects a packaged source scan with the editor's live `inspectSemanticCatalog`; it never replaces official routing:

- `official_buildmode`: use `scene_configure_ability`.
- `local_overlay`: use `scene_configure_ability_overlay` only when `writable=true`, after proving the exact object has the named Ability attached.
- `ugc_authoritative_overlay`: use only the returned `dedicatedTool`.
- `contract_conflict` or `unsupported`: report the structured gap and do not substitute a similar path or codec.

For `ItemAbility.saleCurrency`, never use the stale official string route or the generic overlay writer. First select an exact live `CustomCurrency` key from `currency_info_catalog_overlay`, then call `scene_configure_currency_info_overlay`; completion requires exact readback of both `.type` and `.count`. Never retry an ambiguous mutation before reconciling those leaves. Read [ability-overlay.md](references/ability-overlay.md) for classifications, supported value shapes, regeneration policy, and runtime-test requirements.

## Custom logic workflow

Runtime custom logic uses UGC user components. Follow the installed project Skills and API declarations. Discover and read existing components only from project-local `DataFile/userComponent/description/*.data` and `classes/*.js.mfile`; `sideapi_user_component_read`, `inspectUserComponents`, and `inspectUserComponentApi` are intentionally unavailable. Create only when no suitable owner exists, apply against the positive `componentRevision` read from the local description file, then require the same local files to refresh with an incremented revision and exact managed-state/source readback. API selection and gameplay orchestration belong to the initialized UGC project rather than the MCP runtime.

For client runtime UI properties, load the installed `ui-edit` and `custom-component` Skills together. Treat packaged declarations as static API evidence only, then require live method preflight, structured peer handling, exact runtime readback, and the UI verification levels in [verification.md](references/verification.md).

For an editor-authored UI widget, discover its real canvas/widget GUIDs and canonical property values, then use the MCP-only guarded `ui_widget_adopt` and `ui_widget_patch` semantic tools. `ui_widget_adopt` is a read-only identity/context confirmation; it never rewrites a whole `.ui` merely to store requested description/role/tags. `ui_widget_patch` accepts only its declared safe `CustomUIProperties` leaf catalog and additionally proves every requested path exists on the exact target and is not property-bound before writing; never infer a path from another widget type. The MCP treats the canonical editor-project disk source as the optimistic-concurrency truth even when editor `readUiFile` reports `session-cache`; inspect `sourceProvenance` rather than assuming cache and disk match. The first call obtains that persisted-disk SHA; a mutation must echo it and exact expected old values. `UI_WIDGET_NOT_PERSISTED` means the live widget has not reached the canonical disk source yet: save the canvas in the editor and rediscover it, never fall back to the cached whole document. The patch itself uses the editor's in-place widget Changed command and normal dirty-document incremental save pipeline; it must never call whole-canvas save/unload/remount. Completion requires `outcome=succeeded_verified`, every `propertyReadback.ok=true`, and `structureReadback.ok=true`. `canonicalDiskPersistenceObserved=false` means only that the editor had not flushed its dirty document when the tool returned; do not replace the canvas to force persistence.

The MCP `build_ui_screen` wrapper treats visual-composition quality findings as `uiQuality.advisoryIssues`, while structural and safety findings remain `blockingIssues`. This relaxation is MCP-local; do not infer that Honey or direct callers use the same gate.

## Safety boundary

- Do not use private Legacy structured execution when a named semantic tool exists.
- Do not use a successful transport response as proof of editor state; require semantic readback.
- Do not delete, overwrite, or broadly rewrite editor content unless the user requested that exact scope.
- Do not claim completion when the contract does not match, the bridge is not ready, or required readback is incomplete.
- Treat `sideapi_user_component_apply` arrays as complete replacements and never apply against a stale revision.
- Do not treat project-local UserComponent source readback as proof of network/runtime behavior.
- Do not treat packaged API declarations, caller-supplied authority, or a `runtime=client` tag as proof that the connected runtime loaded the method or that the component executes on a client peer.
- Never describe a UserComponent as client-only unless the apply schema and exact readback prove an execution-side setting. Handle `CLIENT_ONLY` as a structured peer result, not as a JavaScript exception.
- Do not use removed catalog, case, or mechanism lookup tools; consult the initialized project files instead.
- For `mechanism_create_spawner`, completion requires `outcome=succeeded_verified`; an ambiguous transport result must be reconciled, not blindly replayed.
