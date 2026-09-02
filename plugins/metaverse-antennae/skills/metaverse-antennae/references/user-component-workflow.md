# User Component workflow

Use this workflow when runtime gameplay requires a new or modified User Component. Official components and systems remain the authoritative state owners; a User Component should add only missing behavior or coordinate existing owners.

## Evidence order

Read only what the requested behavior needs:

1. Inspect `projection="user_component_api"` for the bindings actually injected into User Component code.
2. Treat the current project's `DataFile/userComponent/docs` as the authoritative API root. If the current workspace is that UGC project, use local workspace search/read facilities on this relative directory and progressively read only relevant `.d.ts` files. This path remains usable while the editor bridge is offline. If the UGC project is not the current accessible workspace, use `code.search_project_source` with `directory="DataFile/userComponent/docs"` and a narrow `*.d.ts` pattern/query, then use `code.read_project_source` on each relevant match. Do not substitute declarations from the MCP package, an installed plugin cache, a sibling checkout, Memory Hub, or model memory.
3. Discover existing components with `inspect(projection="user_components")`. Read a candidate with `code.read_component` before deciding to create or replace anything.
4. Use the component's exact declaration and read-only template for lifecycle hooks and custom events. If the injected bindings, template, and project declarations do not prove a required name, signature, cleanup method, or type, stop that part and report a capability gap.

Never discover the UGC project by scanning unrelated disks or constructing a guessed absolute path. Direct reads are allowed only when `DataFile/userComponent/docs` resolves inside the current verified UGC workspace. Otherwise the editor-connected code Toolset is the authoritative project resolver and bounded read path.

## Component design

Before writing, identify the state owner, trigger or lifecycle, responsibility, dependencies, public configuration, and cleanup responsibility.

- Keep behavior in one component when it has one state owner and compatible lifecycle.
- Split only for a real ownership, lifecycle, reuse, permission, failure-isolation, or enablement boundary.
- Reuse an existing component when its responsibility already matches.
- Keep caches, subscription handles, derived values, transient state, and internal counters private. Expose only stable instance configuration with safe defaults.
- Do not duplicate authoritative state already owned by an official component or system.

Resolve official components and systems only with names and access methods proven by the project declarations. Validate optional and required dependencies before dereferencing them. A dependency failure must log a bounded diagnostic and stop safely; do not invent a replacement API.

## Lifecycle and cleanup

- Acquire dependencies, validate configuration, and bind listeners during the declared initialization hook without duplicate initialization.
- Retain every external callback, subscription, timer, or task handle needed for cleanup.
- In the declared destroy hook, remove listeners, stop timers/tasks, cancel pending callbacks, and release only resources owned by this component.
- Cleanup must be repeatable and safe after partial initialization.
- Prefer events and timers. Do not perform unbounded component/system discovery, attachment, or logging every update tick.
- Any declaration-proven asynchronous readiness retry must be low-frequency, bounded, and stop on success, terminal failure, or attempt exhaustion.

## Logging and runtime evidence

`UserComponentRuntimeBase` provides `this.log(...)`, `this.warn(...)`, and `this.error(...)`. Use those declared methods directly; do not create replacement log functions or look up `LogSystem`.

Runtime logs are buffered while playing. When runtime verification is needed, ask the user to trigger the path and return to edit mode. Only after edit mode is confirmed, read `DataFile/demoLogFile.data` directly when it is inside the verified current UGC workspace. Otherwise use `inspect(projection="runtime_logs")`, or `code.read_project_source` when the editor exposes the persisted project log as source. A log proves that execution reached that record point, not that the whole gameplay outcome completed.

Log bounded scalar values or explicitly formatted summaries. Never log secrets, complete objects, or unbounded payloads, and never emit logs directly from every update tick.

## MCP write and verification sequence

1. Use `catalog_search` and `catalog_describe` to obtain the current schemas for `code.create_component`, `code.read_component`, `code.apply_component`, `code.write_component_body`, and `code.lint` as needed.
2. Create a component only for a new responsibility. Accept only the editor-generated `class_id`; if the result is uncertain, reconcile with `inspect(projection="user_components")` before considering another create.
3. Before modifying an existing component, call `code.read_component` and preserve declarations or regions outside the requested scope.
4. Lint the proposed code before writing.
5. Use `code.apply_component` for a complete managed declaration replacement or `code.write_component_body` for Agent-owned body regions. Submit one planned component at a time.
6. Treat success as complete only when the write Operation returns `succeeded_verified` with hot reload and exact persisted readback. Use `code.read_component` only for diagnosis or reconciliation of an uncertain response.
7. When the target is a preset root, attach the verified `class_id` with `preset.attach_user_component` and require that Operation's exact presence readback.

Completion requires declaration-backed API usage, bounded responsibilities, symmetric cleanup, lint success, and exact semantic readback from every write.
