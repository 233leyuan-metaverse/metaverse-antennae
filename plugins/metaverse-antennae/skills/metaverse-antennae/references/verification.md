# Verification

Every write needs semantic evidence from the editor.

The write Operation's own `succeeded_verified` response is the primary evidence. Do not add a blanket inspect before or after every write. Use the reads below only for explicit discovery, diagnosis, or reconciliation of an `uncertain` result.

## Scene objects

Use `inspect(projection="scene_object_detail", game_object_ids=[...])` for an explicitly requested object detail and `inspect(projection="property_values", queries=[...])` for surgical property diagnosis. Use `inspect(projection="scene_object_attachments", game_object_ids=[...])` for attachments. A paginated `scene_overview` snapshot is complete only after its final page reports `complete=true`; targeted delete success is proved by the delete Operation's same-ID absence readback, not by scene overview.

## UI

Use `inspect(projection="ui_detail", canvas_guids=[...], widget_guids=[...])` for properties, bindings, events, and ownership. Use `inspect(projection="property_values", queries=[...])` only for a narrowly specified diagnostic.

## User Components

Blockly execution and workspace reads are unavailable through the current MCP policy. For runtime logic, use `inspect(projection="user_component_api")` to establish the bindings actually injected into User Components. Establish UGC UI, Buff, Skill, Ability, and other event/API signatures by reading the relevant project-installed `.d.ts` through `code.search_project_source` and `code.read_project_source`. Establish component lifecycle and custom events from the component declaration or read-only template. Lint the generated code, then rely on `code.user_component.apply` or `code.user_component.write_body` hot-reload plus exact persisted readback. Use `code.read_component` for diagnosis or uncertain-result reconciliation.

## Ambiguous transport results

A timeout or missing response does not prove failure. Inspect the intended target before retrying. Retry only when readback proves the write did not land and the operation is safe to repeat.

## Completion

Report what changed, the real identifiers affected, and the Operation verification that proved the result. Report partial completion or a structured gap when evidence is missing.

For visual acceptance, call `capture` with an explicit useful camera when the current viewport may not contain the target. Use `restore_camera=true` when temporarily reframing. Inspect the returned PNG image content; a successful envelope or screenshot path without readable pixels does not prove that an effect or scene result is visible.
