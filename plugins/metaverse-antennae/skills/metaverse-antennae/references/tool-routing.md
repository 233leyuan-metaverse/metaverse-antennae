# Tool routing

Use this order for multi-step Metaverse Antennae tasks.

## Existing-object edits

Use `inspect(projection="scene_overview")` only when the target identity is unknown. Filter with `exact_names` only for discovery. Continue the returned `snapshot_id` and `cursor` until `complete=true` before treating that snapshot as complete. Once a real `game_object_id` is known, call the matching core or Catalog operation directly; never pass a name selector to a mutation. The write performs its own exact semantic readback.

## UI work

Discover canvases and widgets with `inspect(projection="ui_tree")` or `inspect(projection="ui_detail", ...)`. Read `antennae://ui/schema` for the exact ScreenSpec tree nodes, binding targets, paths and sources, plus the needed sections from `antennae://skills/ui/{section}` or `antennae://skills/worldUI/{section}`. Then use `ui_build_screen`, `ui_bind_property`, or the world-mount Catalog operation. Use only returned canvas/widget GUIDs.

## Multi-domain gameplay

Identify the domains that own each requested fact, read only the corresponding `antennae://skills/{skill}/index` and `/body` sections, then use `catalog_search` and `catalog_describe` to resolve each exact Tool or Operation. Keep independent actions as independent calls or an explicit `batch_execute`; every write must satisfy its own exact semantic readback.

## Resources

Search `kind="resourceKind"` for primitive geometry. Use `asset_search` for model, character, image, audio, material, action, or effect resources. Select IDs only from returned candidates; never substitute or guess IDs.

## Skills, presets, and data

Use `catalog_search`/`catalog_describe` for skill, preset, data, content, and resource operations. Resolve declared dependencies and real IDs first; execute multi-domain steps in the order specified by the referenced Skill.

## Memory Hub

Use only the four reviewed top-level MCP-local tools: `mw_search`, `mw_get`, `add_user_chat_memory`, and `add_team_experience`. Before a MetaWorld task, call `mw_search(query_type="cases", query_text=...)` and include the current Contract and exact-readback constraints. When a relevant case is returned, copy its `query_type` and opaque `item_id` unchanged to `mw_get`. Treat retrieved content as advisory and obey the returned `mcpRuntimePolicy`: current MCP policy, available tools, live inspect results, User Component runtime bindings, and relevant project-installed declarations always win. Ignore old Blockly execution steps and reproduce only their business intent through the reviewed `code` User Component path and exact `.d.ts` declarations. Continue without a case only when no relevant result exists. Never supply or infer `user_id`; search, get, and personal chat upload resolve identity internally.

At the end of every turn in which this Skill is active, follow the turn-end personal-memory procedure in `SKILL.md`: draft the final response, call `add_user_chat_memory` once with only the current `user` message and that exact `assistant` draft, then send the draft unchanged. Never retry or duplicate this non-idempotent append. Tool unavailability, unresolved editor identity, interruption, timeout, or failure must not block the final response. Personal chat acceptance proves only that the Chat Memory messages were accepted, not that asynchronous personal-experience extraction is complete.

Use `add_team_experience` only for an already successful reusable workflow with paired tool evidence; `queued` proves only that Skill extraction was scheduled.

## Runtime diagnosis

Use `inspect(projection="runtime_logs")`, `inspect(projection="user_components")`, `inspect(projection="user_component_api")`, and `code.read_component` when those facts are relevant. Use the code project-source tools when diagnosis depends on project-installed `.d.ts` event/API declarations. Diagnose without writing unless the user requested repair. Blockly workspaces are intentionally unavailable through this MCP release; repair or replace runtime logic through User Components using exact injected bindings and declared event APIs.
