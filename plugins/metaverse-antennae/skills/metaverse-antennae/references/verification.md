# Verification

Every write needs semantic evidence from the editor.

The write Operation's own `succeeded_verified` response is the primary evidence. Do not add a blanket inspect before or after every write. Use the reads below only for explicit discovery, diagnosis, or reconciliation of an `uncertain` result.

## Scene objects

Use `inspect(projection="scene_object_detail", game_object_ids=[...])` for an explicitly requested object detail and `inspect(projection="property_values", queries=[...])` for surgical property diagnosis. Use `inspect(projection="scene_object_attachments", game_object_ids=[...])` for attachments. A paginated `scene_overview` snapshot is complete only after its final page reports `complete=true`; targeted delete success is proved by the delete Operation's same-ID absence readback, not by scene overview.

## UI

Use `inspect(projection="ui_detail", canvas_guids=[...], widget_guids=[...])` for properties, bindings, events, and ownership. Use `inspect(projection="property_values", queries=[...])` only for a narrowly specified diagnostic.

## User Components

Blockly execution and workspace reads are unavailable through the current MCP policy. Memory content and static Blockly resources remain advisory migration knowledge and cannot override the `mcpRuntimePolicy` returned by Memory tools. The current project's `DataFile/userComponent/docs/**/*.data` files are the sole public User Component API contract. Establish UGC UI, Buff, Skill, Ability, and other business signatures from `docs/ugc` first; resolve referenced `mw.*` types and engine-level APIs from `docs/engine` second. In particular, types such as `mw.Vector` and `mw.Rotation` require their engine declarations. Read files directly when they resolve inside the current verified UGC workspace; otherwise locate declarations with `code.search_project_source(pattern="*.data")`, then read the matched file with `code.read_project_source`. Never guess an absolute path or substitute declarations from the MCP package, an installed plugin cache, or a sibling checkout. Establish component lifecycle and custom events from the component declaration or read-only template. Before using an `ISubSystem`, verify `IScene.findSystem(...)` in `common.data` and acquire it only through `this.entity.scene.findSystem("ExactSystemClassName")`; `.ins`, `getInstance()`, and module/global singleton access are invalid User Component acquisition paths. Lint the generated code, then rely on `code.user_component.apply` or `code.user_component.write_body` hot-reload plus exact persisted readback. Use `code.read_component` for diagnosis or uncertain-result reconciliation. Exact bounded reads of `dist/game.js` are diagnostic-only and bundle-only symbols do not establish callable API.

## Ambiguous transport results

A timeout or missing response does not prove failure. Inspect the intended target before retrying. Retry only when readback proves the write did not land and the operation is safe to repeat.

## Completion

Report what changed, the real identifiers affected, and the Operation verification that proved the result. Report partial completion or a structured gap when evidence is missing.

For visual acceptance, call `capture` with an explicit useful camera when the current viewport may not contain the target. Use `restore_camera=true` when temporarily reframing. Inspect the returned PNG image content; a successful envelope or screenshot path without readable pixels does not prove that an effect or scene result is visible.
