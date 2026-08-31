# Tool routing

Use this order for multi-step Buildmode tasks.

## Scene generation (preferred)

For new geometry / layout / architecture content:

1. Call `lookup_skill` for `three-scene`.
2. Emit **one** ThreeCompat JS `source` covering the whole main structure and call `three_scene_run` once. The editor client already yields frames while spawning; do **not** split batches to avoid hitching or timeouts.
3. **Do not** call `search_asset` or `lookup_basic_model` before the main structure is generated. Asset library is decoration-only and comes **after** `three_scene_run` succeeds.
4. Batch only when the user should **see an early partial result**. Then: first call `clearPrevious=true` (default); every later batch **must** pass `clearPrevious=false`.
5. Verify with `inspectSceneOverview` against returned `createdGameObjectIds`.
6. Only then optionally `search_asset` + `scene_create_object` for props/characters/effects.

Use `three_scene_bake_asset` when only a local mesh GUID is needed.

Do **not** use archived heightmap / `compile_scene_plan` / `object_supply` whole-scene routes.

## Existing-object edits

Discover with `inspectSceneOverview(limit=1000)`. When its pagination says `complete=false`, continue with the returned `snapshotId` and `nextCursor` until `complete=true`; never treat a partial page as proof that an object is absent. Narrow with `inspectSceneObjectDetail`, call the matching `scene_*` tool, then verify exact paths with `inspectPropertyValues`.

## UI work

Discover canvases and widgets with `inspectUiTree`, read selected targets with `inspectUiDetail`, then call `ui`, `ui_bind_property`, or `world_ui_mount` from their exposed schemas. Verify the widget/canvas detail and exact properties.

Choose runtime display routes by consistency: use property binding or existing UI Instruction paths for authoritative/multi-client display, and reserve client runtime property APIs for current-client temporary unbound visuals. During runtime-property diagnosis, freeze design-time UI; a runtime failure does not authorize rebuilding the canvas or adding fallback widgets.

## Gameplay mechanisms

Use the named semantic tools and their exposed schemas directly for the distinct goal.

When runtime custom logic is required, route it through a UGC user component. Legacy case or skill guidance that requires Blockly or direct InstructionList authoring is unsupported on this MCP surface.

## Resources

For **new scene builds**, skip this section until after `three_scene_run` has landed the main structure. Primitives and layout belong in ThreeCompat JS, not asset search.

After the main scene exists (or for non-scene tasks), use `lookup_basic_model` for preset primitives and `search_asset` for model / character / image / audio / material / action / effect. Select IDs only from returned candidates; never substitute or guess IDs.

## Skills, presets, and data

Use the named `skill_*`, `preset_*`, `*_data_manage`, and resource tools. Resolve dependencies and IDs first. Follow lookup case ordering when creation spans more than one domain.

## Runtime diagnosis

Read runtime logs, the relevant object or UI details, and the current user component state. Diagnose without writing unless the user requested repair. Repair component code only after API evidence and revision-aware readback.
