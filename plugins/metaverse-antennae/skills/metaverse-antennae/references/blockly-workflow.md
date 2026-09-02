# Blockly workflow

Blockly is available only through the `blockly` Catalog Toolset; there is no top-level `blockly_compile` tool.

1. Read `antennae://blockly/schema` and the relevant Event/Instruction resources.
2. Discover and describe the `blockly` Toolset, then invoke `compile`, `read_workspace`, `list_workspaces`, or `delete_workspace` through `catalog_invoke`.
3. Use strict targets and event paths. `skillAsset` accepts only `abilityGraph.childrenTracks.{track}.clips.{clip}.asset.abilityTask.onTaskActivated` or `.onTaskEnded`.
4. Use `preset.replace_event` for atomic preset-root event replacement; do not manually expose or compose preset edit sessions.
5. Require exact workspace-source and same-target binding readback.

Use User Components instead for broader runtime systems. Inspect `projection="user_component_api"`, read exact project `.d.ts` declarations through the `code` Toolset, lint before writing, and require hot-reload plus exact persisted readback.
