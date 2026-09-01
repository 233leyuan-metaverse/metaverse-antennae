# Blockly workflow

## Required sequence

1. Use `catalog_search` to find the business Event, Runtime Instruction and owning Skill.
2. Read `antennae://events/{skill}` for the exact event path, target variant and argument slots.
3. Read only the needed `antennae://blockly/instructions/{name}` entries and business Skill sections.
4. Read `antennae://blockly/schema` when constructing or repairing node structure.
5. For replacement, obtain the exact existing workspace name from the target event binding and read that workspace.
6. Call `blockly_compile` once with `workspace_name`, `target`, `event_path`, `mode`, optional `variables`, and `statements`.
7. Accept completion only when the returned source and exact event-binding readbacks are both verified.

## Hard rules

- Never invent ability IDs, Event paths, argument positions, target IDs, canvas GUIDs or widget GUIDs.
- Submit only the documented Blockly program fields; editor-internal source and compatibility fields are rejected.
- `mode=create` never silently deduplicates a workspace name. `mode=replace` reuses the exact existing bound name.
- `allow_additional_binding=true` requires an explicit user request for parallel handlers on the same event.
- Workspace list is browse-only and may omit script-only workspaces; it is not success or absence evidence.
- Never retry a timeout or uncertain result blindly. Read the exact workspace and binding first.
- Runtime object destruction uses Blockly `DestroyEntity`; edit-time scene deletion uses `scene_delete_object`.

## Resource selection

- Recursive DSL fields and 32 node variants: `antennae://blockly/schema`.
- Event signatures: `antennae://events/{skill}`.
- One Instruction: `antennae://blockly/instructions/{name}`.
- Ability runtime property path: `antennae://abilities/{ability}/properties` plus the business Skill.
- General process and examples: `antennae://skills/blockly-dsl/body` and `/examples`.
