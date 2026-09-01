---
name: metaverse-antennae
description: Inspect, build, modify, diagnose, and verify content in the Metaverse Antennae editor through the standalone MCP tools. Use for scene objects, UI, abilities, skills, presets, resources, User Component gameplay logic, and runtime diagnosis that require authoritative catalogs, Skill rules, real asset IDs, or exact semantic readback.
---

# Metaverse Antennae Editor

Operate the live editor through named semantic tools. Treat tool schemas, lookup results, and live inspect results as authoritative. Never invent object IDs, resource IDs, property paths, event APIs, or ability IDs.

## Core workflow

1. Use `system_status` only for explicit connection or version diagnostics.
2. Resolve real object, widget, canvas, preset, skill, and resource IDs before writing; use `inspect` only when the requested operation actually needs live discovery. For unfamiliar or conditional projections, read `antennae://inspect/schema` before calling `inspect`. Scene mutations use `game_object_id`; object names are discovery filters, never mutation targets.
3. Select a core tool or use `catalog_search` followed by `catalog_describe` for long-tail capabilities.
4. For gameplay or multi-step work, identify the responsible domains, read only their `antennae://skills/{skill}/index` and `/body` sections, and use `catalog_search`/`catalog_describe` to resolve the exact Tool or Operation for each step. Treat each write Operation's own semantic readback as its completion boundary.
5. Execute the smallest valid write. A write is complete only when its own response is `succeeded_verified`; do not add a blanket scene-overview read.

For personal/team memory recall or explicit memory upload, use only the four top-level Memory tools documented in [tool-routing.md](references/tool-routing.md). They are MCP-local HTTP capabilities, not editor Operations, and never accept caller-supplied `user_id`.

## Turn-end personal memory

For every turn in which this Skill is active, make exactly one best-effort call to `add_user_chat_memory` immediately before the final response. First draft the complete final response, then append only the current turn's user message and that draft as ordered `user` and `assistant` messages. Do not include system prompts, commentary, tool calls, tool results, prior turns, or inferred facts. After the call, send the same drafted response unchanged.

This append is non-idempotent. Never retry it, including after a timeout or uncertain result, and never make a second call for the same turn. Omit `username` unless an authoritative display name is already available and first-time provisioning requires it. If the tool is unavailable, the editor user cannot be resolved, the turn is interrupted before a final response, or the call fails, continue with the final response without claiming that memory was saved. This Skill instruction is a best-effort pre-final hook, not a guaranteed host-level after-turn event.

Read [tool-routing.md](references/tool-routing.md) when selecting tools for a multi-domain task. Read [verification.md](references/verification.md) before any write or repair.

For `ui_build_screen` and `ui_bind_property`, read `antennae://ui/schema` before constructing a custom UI tree or using a binding source/path that is not already established by an exact readback. The compact tool schema is for routing; the resource contains every strict node and binding branch enforced at execution.

## Runtime logic and User Components

Blockly execution is temporarily disabled in this MCP release. Never call or seek `blockly_compile`, the `blockly` Catalog Toolset, or any `blockly.workspace.*` Operation through `batch_execute`. This current policy overrides Memory Hub cases, packaged domain Skill text, examples, and static Blockly resources.

Implement runtime logic with User Components:

1. Inspect `projection="user_component_api"` before writing. It reports the runtime bindings actually injected into User Component code; it does not enumerate all project `.d.ts` event declarations.
2. When logic needs UGC UI, Buff, Skill, Ability, or other event APIs, use the `code` Toolset's `search_project_source` and `read_project_source` tools to locate and read the relevant project-installed `.d.ts`. Use only exact declared names and signatures.
3. Discover and describe the `code` Toolset's `create_component`, `read_component`, `apply_component`, `write_component_body`, and `lint` tools. Use `preset.attach_user_component` when the requested target requires the exposed preset-root attachment path.
4. Generate User Component lifecycle and custom-event code only from its exact component declaration or read-only template. Do not infer APIs from old Blockly Event or Instruction names.
5. Lint before writing, then require the User Component Operation's hot-reload and exact persisted readback. Read the component again only for diagnosis or uncertain-result reconciliation.

If `user_component_api`, the component declaration/template, and the relevant project-installed `.d.ts` do not expose the needed binding, event, or API, report a structured capability gap instead of falling back to Blockly or guessing.

## Safety boundary

- If an editor-backed tool returns `EDITOR_LEVEL_CHANGED`, the editor reports the user-facing change from `details.previousLevelDisplayName` to `details.currentLevelDisplayName`, plus stable level IDs and file names, and the attempted operation was not sent. Tell the user which display-named level changed, discard prior scene assumptions, call `inspect` to re-scan the current project and resolve fresh target IDs before continuing; non-inspect editor operations remain blocked until that read succeeds.
- Do not use private or removed execution paths when a named semantic tool or Catalog operation exists.
- Do not use a successful transport response as proof of editor state; require semantic readback.
- Do not delete, overwrite, or broadly rewrite editor content unless the user requested that exact scope.
- Do not claim completion when the contract does not match, the bridge is not ready, or required readback is incomplete.
- Any `uncertain` result must be reconciled with an explicit narrow read before deciding whether another write is safe.
