---
name: metaverse-antennae
description: Inspect, build, modify, diagnose, and verify content in the Metaverse Antennae editor through the standalone MCP tools. Use for scene objects, UI, abilities, skills, presets, resources, User Component gameplay logic, and runtime diagnosis that require authoritative catalogs, Skill rules, real asset IDs, or exact semantic readback.
---

# Metaverse Antennae Editor

Operate the live editor through named semantic tools. Treat tool schemas, lookup results, and live inspect results as authoritative. Never invent object IDs, resource IDs, property paths, event APIs, or ability IDs.

## Core workflow

1. Use `system_status` only for explicit connection or version diagnostics.
2. Begin every Metaverse task with intent-level `authoring_api_search` and exact `authoring_api_doc`. The only business-data exception is `asset_search`, which may run first to resolve a real external asset ID. `system_status` and the Memory append tools are infrastructure exceptions, not alternate execution or discovery routes. Do not call MWSearch, Skill Resources, Inspect, core tools, Catalog Search/Describe/Invoke, or Batch before Authoring discovery proves a concrete capability gap.
3. Preserve the user's original intent before choosing an execution route. Every editor mutation—including create, modify, delete, batch, design, assemble, and other execution work—must be covered by intent-level `authoring_api_search`, exact `authoring_api_doc`, and `authoring_code_execute`, followed by bounded exact semantic readback. For one independently owned mutation intent, start with one precise Search query; do not repeat synonymous Search queries after an exact callable symbol is found. Doc each final callable symbol once. Treat compact Doc `pendingTypes` as informational, not a to-do list: expand only a type whose missing fields, signature, runtime access, constraint, or readback semantics actually block safe code generation. Never recursively Doc the complete type graph, basic engine types, display-only DTOs, or types unused by the planned body. Within the same current user task, reuse exact Search/Doc results already returned only when the editor session, active project and level are unchanged, the requested semantics use the same documented symbols, no declaration-changing operation occurred, and no execution or transport uncertainty exists. Keep a small current-task evidence set keyed by exact symbol so the same symbol is not documented twice. Never reuse discovery across tasks, turns, restarts, `EDITOR_LEVEL_CHANGED`, active-project changes, new symbols or semantics, or as evidence for a different captured fallback route. Every mutation still requires its own bounded Exec and exact semantic readback.
4. MWSearch, Skill Resources, Inspect, and Catalog are fallback reference/read paths. Use them only through the captured `authoring_route_fallback` after Search/Doc proves the exact missing operation, identity, schema, terminology, or readback semantic. Prefer the narrowest complete fallback lookup. After obtaining missing reference facts, start a fresh Authoring discovery route for any resulting mutation; fallback evidence never authorizes direct execution.
5. A named semantic tool or Catalog handler may run only through `authoring_route_fallback` after the current captured route's own searched and documented public Authoring declarations prove a concrete capability gap. Search/Doc reuse may guide public Authoring execution, but never authorizes a fallback. If the route gate returns `AUTHORING_ROUTE_REQUIRED`, treat `routing.queries` only as optional, non-exhaustive starting hints rather than a required search set, whitelist, or capability boundary; the list may be empty. Search from the original intent, inspect exact hits, and follow relevant declarations, parameter types, and dependencies freely. Never fall back after `executed=true` or execution uncertainty.
6. For gameplay or multi-step work, keep each independently owned action separate unless the discovered Authoring workflow safely composes them. When optional reference material is required, identify the responsible domains, read only their needed `antennae://skills/{skill}/index` and `/body` sections, and load a dependency body only when its conditional subflow is part of the user's request. Treat each write Operation's own semantic readback as its completion boundary.
7. Execute the smallest valid write. A write is complete only when its own response is `succeeded_verified`; do not add a blanket scene-overview read.

### Authoring context discipline

- Keep `authoring_api_search` results bounded with `limit <= 8`.
- Use compact Authoring Doc by default. Do not request `detail="full"` for an entire class; expand only an exact blocking symbol or referenced type when compact detail is insufficient for safe execution.
- When exact target IDs are already known and still valid in the current task context, do not call `getAllEntities()`.
- Keep `authoring_code_execute` results surgical: return only changed fields, aggregate counts, and mismatches needed for exact semantic readback. Do not return complete entities, component graphs, transforms, bounds, or material arrays unless the requested verification requires them.
- After successful exact readback, do not add a broad scene overview or full-scene Inspect. If readback reports a mismatch, narrow-read only the affected target and fields before deciding whether another mutation is safe.
- Reuse completed Search/Doc evidence within the same current user task only under the unchanged-context conditions above.
- Stop when the requested stage and its required readback are complete; do not broaden the verification scope without a concrete failure or an explicit user request.

`capture` remains available for visual acceptance when useful. Its use does not replace semantic readback, and this context discipline does not require or forbid it.

For personal/team memory recall or explicit memory upload, use only the four top-level Memory tools documented in [tool-routing.md](references/tool-routing.md). They are MCP-local HTTP capabilities, not editor Operations, and never accept caller-supplied `user_id`.

## Turn-end personal memory

For every turn in which this Skill is active, make exactly one best-effort call to `add_user_chat_memory` immediately before the final response. First draft the complete final response, then append only the current turn's user message and that draft as ordered `user` and `assistant` messages. Do not include system prompts, commentary, tool calls, tool results, prior turns, or inferred facts. After the call, send the same drafted response unchanged.

This append is non-idempotent. Never retry it, including after a timeout or uncertain result, and never make a second call for the same turn. Omit `username` unless an authoritative display name is already available and first-time provisioning requires it. If the tool is unavailable, the editor user cannot be resolved, the turn is interrupted before a final response, or the call fails, continue with the final response without claiming that memory was saved. This Skill instruction is a best-effort pre-final hook, not a guaranteed host-level after-turn event.

Read [tool-routing.md](references/tool-routing.md) when selecting tools for a multi-domain task. Read [verification.md](references/verification.md) before any write or repair.

For `ui_bind_property`, when the source kind is known, read only its branch with `catalog_describe(kind="operation", item_id="ui.property.bind", projection="input_only", selectors=[{"field":"kind","value":<source kind>}])`. For `ui_build_screen`, call `catalog_describe(kind="tool", item_id="build_screen", projection="input_only")` first; read `antennae://ui/schema` only when constructing a custom tree that genuinely uses definitions or multiple node branches not retained by the exact input description. The full Resource remains authoritative for those requested branches, but it is not the default routing read.

## Runtime logic, Blockly, and User Components

Blockly execution and workspace reads are temporarily disabled through this MCP. Memory, old cases, static Event/Instruction resources, editor capability status, and existing workspaces are advisory migration context only; they never authorize `blockly.workspace.*`, the preset workspace compatibility Operations, Catalog Blockly, or Batch execution. Do not delete existing Blockly data unless the user explicitly requests a separately supported cleanup path.

Use User Components for authored runtime systems:

Before creating or modifying a User Component, read and follow [user-component-workflow.md](references/user-component-workflow.md). It restores the evidence, design, lifecycle, logging, write, and readback workflow used by the dedicated custom-component Skill. API declarations may be read from the verified current UGC workspace; component mutations and semantic readback use the current MCP tools.

1. Treat all `DataFile/userComponent/docs/**/*.data` files as the sole public User Component API contract. Read the relevant `docs/ugc` domain declaration first, followed by `common.data` and `decorate.data` only as needed. When a UGC signature references `mw.Vector`, `mw.Rotation`, or another `mw.*` engine symbol, or the task needs an engine-level API, read the matching declaration under `docs/engine`. When the current workspace is the UGC project, use workspace-relative reads; otherwise use the `code` Toolset's `search_project_source` and `read_project_source` with `pattern="*.data"`. Never guess an absolute project path or substitute declarations from the MCP package, an installed plugin cache, or a sibling checkout.
2. Use `IScene.createEntity(...)` to create gameplay entities and `IEntity.destroy(...)` to destroy them when those signatures are declared. Do not bypass the entity system with raw engine spawn/destroy calls unless the UGC declaration explicitly requires a non-entity engine object.
3. Acquire every scene system declared as `ISubSystem` from the current component's scene with `this.entity.scene.findSystem("ExactSystemClassName")`, after reading the `IScene.findSystem(...)` declaration in `common.data`. Never use `api.<System>.ins`, `<System>.ins`, `getInstance()`, or a module/global singleton shortcut, even when a static accessor is present in `.data` or observed in `dist/game.js`. If the current scene cannot provide the system, log a bounded diagnostic and stop safely; do not fall back to a singleton.
4. Declare persisted public properties through `apply_component.properties`; the generated shell owns `api.property`, `api.serializable`, `api.displayName`, and `api.editorType`. Keep transient state private and do not edit the generated decorator region.
5. Discover the public User Component creation, read, write, lint, and preset-attachment entrypoints through Authoring Search/Doc. Only after an exact Authoring gap may the captured `code` or `preset` Catalog path run through `authoring_route_fallback`.
6. Generate User Component lifecycle and custom-event code only from its exact component declaration or read-only template. Do not infer APIs from old Blockly Event or Instruction names.
7. Lint before writing, then require the User Component Operation's hot-reload and exact persisted readback. Read the component again only for diagnosis or uncertain-result reconciliation. Read exact `dist/game.js` segments only as a last-resort diagnostic when declarations and runtime behavior conflict; bundle-only symbols are not public API.

If neither the component declaration/template nor the relevant project-installed `DataFile/userComponent/docs/**/*.data` exposes the needed binding, event, type, or API after checking UGC declarations first and referenced engine declarations second, report a structured capability gap instead of guessing or falling back to Blockly.

## Safety boundary

- If an editor-backed tool returns `EDITOR_LEVEL_CHANGED`, the editor reports the user-facing change from `details.previousLevelDisplayName` to `details.currentLevelDisplayName`, plus stable level IDs and file names, and the attempted operation was not sent. Tell the user which display-named level changed, discard prior scene assumptions, call `inspect` to re-scan the current project and resolve fresh target IDs before continuing; non-inspect editor operations remain blocked until that read succeeds.
- Do not use private or removed execution paths when a named semantic tool or Catalog operation exists.
- Do not use a successful transport response as proof of editor state; require semantic readback.
- Do not delete, overwrite, or broadly rewrite editor content unless the user requested that exact scope.
- Do not claim completion when the contract does not match, the bridge is not ready, or required readback is incomplete.
- Any `uncertain` result must be reconciled with an explicit narrow read before deciding whether another write is safe.
