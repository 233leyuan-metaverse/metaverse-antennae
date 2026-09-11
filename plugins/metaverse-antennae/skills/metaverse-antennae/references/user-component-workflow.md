# User Component workflow

Use this workflow when runtime gameplay requires a new or modified User Component. Official components and systems remain the authoritative state owners; a User Component should add only missing behavior or coordinate existing owners.

## Evidence order

First check `DataFile/userComponent/templates/` in the verified current UGC project. If the target component already has a template, read it completely; otherwise, an existing template in that directory can provide shared authoring guidance. Resolve filenames from the current directory or tool results, not a fixed example class ID. Read the relevant `.data` declarations for the requested behavior.

Templates are generated after the component's first creation/write, so an empty or absent templates directory before that step is expected and is not a blocker. For a new component, use the supported creation/initial-write operation and verified declarations to establish the minimal component shell, then read its actual generated template before adding gameplay logic. For an existing component with no template yet, use its current declaration and the supported initial write that generates the template, preserving existing code. Use the editor-returned `class_id` to identify the target template; do not copy another component's class ID or overwrite generated template files. Report a capability gap only for required APIs that cannot be established from the available declarations, not merely for the absence of a sample template.

Generated template headers provide authoring guidance for lifecycle methods, component lookup, scene system lookup, `api.remoteCall`, `api.replicable`, endpoint checks and project environment checks. Register listeners in Activated, remove them in Deactivated (including runtime-to-edit), and reuse idempotent cleanup in Destroy. Awaked initializes an instance once; Started initializes each runtime entry; Update handles active frame work.

For enum-typed arguments, comparisons and decorator options in generated JS, read the relevant `.data` enum declaration and use the selected member's actual value directly as a literal. Preserve its type: string values become string literals; numeric values become numeric literals. For example, the declaration `NumberInput = "NumberInput"` means passing `"NumberInput"`, and `build = "build"` means passing `"build"`. Resolve values from the declaration rather than member names; if a value is unavailable, report the declaration gap. This rule applies to enums only: `mw.Server`, `mw.Client`, and `mw.Multicast` are FunctionOption objects, so retain them in RPC decorators.

Use `mw.SystemUtil.isClient()` and `mw.SystemUtil.isServer()` independently; both may be true. The requested project-state API is `GameUtil.getCurrentEnvironment()` (the checked implementation is named `GameUtils.getCurrentEnvironment()`). Verify its public runtime binding before use and do not substitute `getCurrentEnv()`.

Acquire other components with `this.entity.getComponent("ExactComponentClassName")` and scene systems with `this.entity.scene.findSystem("ExactSystemClassName")`, using declaration-proven names and checking for absence. Read `decorate.data` before RPC or replication; network replication and persistence via `serializable` have different purposes.

Configure RPC through ordinary `replace.functions` entries with `remoteCall: "server" | "client" | "multicast" | "none"`. SideAPI `code.apply_component` uses `functions[].remote_call`. The generator applies `api.remoteCall` in the managed class decoration region; no class-external source injection is needed. For an existing method declared through `replace.functions`, update its marker through `writeBody` declarations `rpcMethods: [{ name, remoteCall }]` (SideAPI: `rpc_methods: [{ name, remote_call }]`). `client` follows the runtime's target-player argument convention, and `multicast` follows runtime visibility scope; verify the relevant API semantics before calling. Server methods still validate permissions, arguments and request frequency.

Set `replicated: true` or `false` on a `properties` entry or an incremental `requiredProperties` declaration (SideAPI: `required_properties`). The generator applies or removes `api.replicable()` without changing existing persistence behavior. Omitted RPC/replication fields preserve existing settings; new methods default to ordinary methods and new properties default to no replication. Explicit `none`/`false` disables a setting. Use the generated internal property field name from the target template, not its display name. The structured replication field is a boolean only; it does not expose `onChanged` or owner-only options. Verify these fields in the current writer's declarations before submitting, and preserve managed decorator regions.

Read only what the requested behavior needs:

1. Treat every `DataFile/docs/**/*.data` file in the current project as part of the sole public API contract. Search `DataFile/docs/ugc` first with `pattern="*.data"`: read the relevant domain file, then `common.data` and `decorate.data` only as needed. If a UGC signature references `mw.Vector`, `mw.Rotation`, or another `mw.*` symbol, or the task requires an engine-level API, search `DataFile/docs/engine` with the same pattern and read only the matching declarations. If the current workspace is that UGC project, use workspace-relative reads; otherwise use `code.search_project_source` and `code.read_project_source`. Do not substitute declarations from the MCP package, an installed plugin cache, a sibling checkout, Memory Hub, or model memory.
2. Discover existing components with `inspect(projection="user_components")`. Read a candidate with `code.read_component` before deciding to create or replace anything.
3. Use the component's exact declaration and, once generated, its read-only template for lifecycle hooks and custom events. Follow the initial creation/write sequence above when no template exists yet. If the available evidence does not prove a required name, signature, cleanup method, or type, stop only that unsupported part and report a capability gap.
4. Read `dist/game.js` only through the exact bounded project-source escape hatch when declarations are missing or conflict with runtime behavior, or a runtime stack requires bundle context. A bundle-only symbol is never authorization to call an undeclared API.

Never discover the UGC project by scanning unrelated disks or constructing a guessed absolute path. Direct reads are allowed only when `DataFile/docs` resolves inside the current verified UGC workspace. Otherwise the editor-connected code Toolset is the authoritative project resolver and bounded read path.

## Entity ownership

Use `IScene.createEntity(...)` to create gameplay entities and `IEntity.destroy(...)` to destroy them when those signatures are declared. Do not bypass the entity system with raw engine spawn/destroy calls unless the UGC declaration explicitly requires a non-entity engine object.

## Component design

Before writing, identify the state owner, trigger or lifecycle, responsibility, dependencies, public configuration, and cleanup responsibility.

- Keep behavior in one component when it has one state owner and compatible lifecycle.
- Split only for a real ownership, lifecycle, reuse, permission, failure-isolation, or enablement boundary.
- Reuse an existing component when its responsibility already matches.
- Keep caches, subscription handles, derived values, transient state, and internal counters private. Expose only stable instance configuration with safe defaults.
- Declare exposed persisted properties through `code.apply_component.properties`. The generated shell owns `api.property({ default: ... })`, `api.serializable`, `api.displayName(...)`, and `api.editorType(...)`; never hand-edit that decorator region.
- Do not duplicate authoritative state already owned by an official component or system.

Resolve official components only with names and access methods proven by the project declarations. For every scene system declared as `ISubSystem`, read `common.data` to prove `IScene.findSystem(...)`, then acquire it from the current component with `this.entity.scene.findSystem("ExactSystemClassName")`. Never use `api.<System>.ins`, `<System>.ins`, `getInstance()`, or a module/global singleton shortcut, even if `.data` exposes one or `dist/game.js` uses one internally. Validate the returned system before dereferencing it; if the current scene cannot provide it, log a bounded diagnostic and stop safely instead of falling back to a singleton.

## Lifecycle and cleanup

- Create gameplay entities through declaration-proven `IScene.createEntity(...)` and destroy them with `IEntity.destroy(removeGo?)`. Do not bypass the entity system with raw `mw.GameObject.spawn/destroy` unless the declaration explicitly requires a non-entity engine object.
- Acquire dependencies, validate configuration, and bind listeners during the declared initialization hook without duplicate initialization.
- Retain every external callback, subscription, timer, or task handle needed for cleanup.
- In Deactivated, remove listeners and stop timers/tasks for the availability period. Reuse the same idempotent cleanup in Destroy as final fallback; returning to edit mode is not destruction.
- Cleanup must be repeatable and safe after partial initialization.
- Prefer events and timers. Do not perform unbounded component/system discovery, attachment, or logging every update tick.
- Any declaration-proven asynchronous readiness retry must be low-frequency, bounded, and stop on success, terminal failure, or attempt exhaustion.

## Logging and runtime evidence

`UserComponentRuntimeBase` provides `this.log(...)`, `this.warn(...)`, and `this.error(...)`. Use those declared methods directly; do not create replacement log functions or look up `LogSystem`.

Runtime logs are buffered while playing. When runtime verification is needed, ask the user to trigger the path and return to edit mode. Only after edit mode is confirmed, read `DataFile/demoLogFile.data` directly when it is inside the verified current UGC workspace. Otherwise use `inspect(projection="runtime_logs")`, or `code.read_project_source` when the editor exposes the persisted project log as source. A log proves that execution reached that record point, not that the whole gameplay outcome completed.

Log bounded scalar values or explicitly formatted summaries. Never log secrets, complete objects, or unbounded payloads, and never emit logs directly from every update tick.

## MCP write and verification sequence

1. Use Authoring Search/Doc to discover the public creation, read, write, lint, and attachment entrypoints. Only after an exact Authoring gap may a captured `code` or `preset` Catalog lookup/invocation run through `authoring_route_fallback`.
2. Create a component only for a new responsibility. Accept only the editor-generated `class_id`; after the first creation/write, read the matching generated template as described above. If the result is uncertain, reconcile with `inspect(projection="user_components")` before considering another create.
3. Before modifying an existing component, call `code.read_component` and preserve declarations or regions outside the requested scope.
4. Lint the proposed code before writing.
5. Use `code.apply_component` for a complete managed declaration replacement or `code.write_component_body` for Agent-owned body regions. Submit one planned component at a time.
6. Treat success as complete only when the write Operation returns `succeeded_verified` with hot reload and exact persisted readback. Use `code.read_component` only for diagnosis or reconciliation of an uncertain response.
7. When the target is a preset root, attach the verified `class_id` with `preset.attach_user_component` and require that Operation's exact presence readback.

Completion requires declaration-backed API usage, bounded responsibilities, symmetric cleanup, lint success, and exact semantic readback from every write.
