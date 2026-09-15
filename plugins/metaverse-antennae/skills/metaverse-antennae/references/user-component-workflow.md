# User Component workflow

Use this workflow when runtime gameplay requires a new or modified User Component. Official components and systems remain the authoritative state owners; a User Component should add only missing behavior or coordinate existing owners.

## Evidence order

This workflow owns the shared authoring guidance and examples; no example file or generated reference template is required in the UGC project. Read the component-design section before first implementation or changing responsibilities, then the relevant examples below. Reuse unchanged evidence within the same task. Examples show syntax, not proof of API availability: verify signatures against the current project declarations.

Use the actual component source and description to establish its generated fields and managed regions. Panel and structured declaration edits must continue to update the actual component code. Register listeners in Activated, remove them in Deactivated (including runtime-to-edit), and reuse idempotent cleanup in Destroy. Awaked initializes an instance once; Started initializes each runtime entry; Update handles active frame work.

For enum-typed arguments, comparisons and decorator options in generated JS, read the relevant `.data` enum declaration and use the selected member's actual value directly as a literal. Preserve its type: string values become string literals; numeric values become numeric literals. For example, the declaration `NumberInput = "NumberInput"` means passing `"NumberInput"`, and `build = "build"` means passing `"build"`. Resolve values from the declaration rather than member names; if a value is unavailable, report the declaration gap. This rule applies to enums only: `mw.Server`, `mw.Client`, and `mw.Multicast` are FunctionOption objects, so retain them in RPC decorators.

Use `mw.SystemUtil.isClient()` and `mw.SystemUtil.isServer()` independently; both may be true. The requested project-state API is `GameUtil.getCurrentEnvironment()` (the checked implementation is named `GameUtils.getCurrentEnvironment()`). Verify its public runtime binding before use and do not substitute `getCurrentEnv()`.

Acquire other components with `this.entity.getComponent("ExactComponentClassName")` and scene systems with `this.entity.scene.findSystem("ExactSystemClassName")`, using declaration-proven names and checking for absence. Read `decorate.data` before RPC or replication; network replication and persistence via `serializable` have different purposes.

Configure RPC through ordinary `replace.functions` entries with `remoteCall: "server" | "client" | "multicast" | "none"`. SideAPI `code.apply_component` uses `functions[].remote_call`. The generator applies `api.remoteCall` in the managed class decoration region; no class-external source injection is needed. For an existing method declared through `replace.functions`, update its marker through `writeBody` declarations `rpcMethods: [{ name, remoteCall }]` (SideAPI: `rpc_methods: [{ name, remote_call }]`). `client` follows the runtime's target-player argument convention, and `multicast` follows runtime visibility scope; verify the relevant API semantics before calling. Server methods still validate permissions, arguments and request frequency.

Set `replicated: true` or `false` on a `properties` entry or an incremental `requiredProperties` declaration (SideAPI: `required_properties`). The generator applies or removes `api.replicable()` without changing existing persistence behavior. Omitted RPC/replication fields preserve existing settings; new methods default to ordinary methods and new properties default to no replication. Explicit `none`/`false` disables a setting. Use the generated internal property field name from the target component source or description, not its display name. The structured replication field is a boolean only; it does not expose `onChanged` or owner-only options. Verify these fields in the current writer's declarations before submitting, and preserve managed decorator regions.

Read only what the requested behavior needs:

Resolve the declaration root first: prefer `DataFile/docs`; only if it is absent or has no `.data` files anywhere beneath it, use `DataFile/userComponent/docs` in the same verified project. All `DataFile/docs` paths below and in domain Skills refer to that selected root, including `ugc` and `engine`. Do not fall back for missing symbols, malformed declarations, skipped/unreadable files, truncated searches or transport failures, and do not merge roots. Project-source searches must use `pattern="*.data"`; zero text matches alone does not prove there are no declaration files—check `scanned_file_count` and `skipped_file_count`. Authoring Search/Doc performs root selection automatically.

1. Treat every `DataFile/docs/**/*.data` file in the current project as part of the sole public API contract. Search `DataFile/docs/ugc` first with `pattern="*.data"`: read the relevant domain file, then `common.data` and `decorate.data` only as needed. If a UGC signature references `mw.Vector`, `mw.Rotation`, or another `mw.*` symbol, or the task requires an engine primitive that does not overlap UGC functionality, search `DataFile/docs/engine` with the same pattern and read only the matching declarations. If the current workspace is that UGC project, use workspace-relative reads; otherwise use `code.search_project_source` and `code.read_project_source`. Do not substitute declarations from the MCP package, an installed plugin cache, a sibling checkout, Memory Hub, or model memory.
2. Discover existing components with `inspect(projection="user_components")`. Read a candidate with `code.read_component` before deciding to create or replace anything.
3. Use the component's exact declarations and actual source for lifecycle hooks and custom events; consult only the relevant sections of this workflow. If the available evidence does not prove a required name, signature, cleanup method, or type, stop only that unsupported part and report a capability gap.
4. Read `dist/game.js` only through the exact bounded project-source escape hatch when declarations are missing or conflict with runtime behavior, or a runtime stack requires bundle context. A bundle-only symbol is never authorization to call an undeclared API.

Never discover the UGC project by scanning unrelated disks or constructing a guessed absolute path. Direct reads are allowed only when `DataFile/docs` resolves inside the current verified UGC workspace. Otherwise the editor-connected code Toolset is the authoritative project resolver and bounded read path.

## Entity ownership

Create runtime gameplay entities on an existing scene instance and destroy them on the target entity instance. `IScene` and `IEntity` name interface contracts, not static call targets: do not emit `IScene.createEntity(...)`, `IScene.create(...)`, or `IEntity.destroy(...)`, and do not construct a new Scene just to create an entity. In a User Component, acquire the owning scene from `this.entity.scene`:

```js
// Inside an async User Component method; assetId must be a verified resource ID.
const scene = this.entity.scene;
const createdEntity = await scene.createEntity(assetId);
```

Retain the returned entity reference for its intended lifetime. When that owned entity should be removed, call `createdEntity.destroy(removeGo)` on that instance; choose `removeGo` from the current declaration and intended GameObject cleanup semantics. Do not substitute `this.entity.destroy(...)` unless the component's own host entity is the intended target. If a helper receives a scene, use that supplied instance instead of a singleton or a newly constructed scene. Verify the selected overload in `common.data` before use.

These are runtime gameplay calls. Editor create/delete operations use the declared Authoring commands. Do not bypass the entity system with raw engine spawn/destroy calls; there is no non-entity exception.

## Component design

Before writing, identify the state owner, trigger or lifecycle, responsibility, dependencies, public configuration, and cleanup responsibility.

- Keep behavior in one component when it has one state owner and compatible lifecycle.
- Split only for a real ownership, lifecycle, reuse, permission, failure-isolation, or enablement boundary.
- Reuse an existing component when its responsibility already matches.
- Keep caches, subscription handles, derived values, transient state, and internal counters private. Expose only stable instance configuration with safe defaults.
- Declare exposed persisted properties through `code.apply_component.properties`. The generated shell owns `api.property({ default: ... })`, `api.serializable`, `api.displayName(...)`, and `api.editorType(...)`; never hand-edit that decorator region.
- Do not duplicate authoritative state already owned by an official component or system. For example, a chest owns its open state, inventory owns player items, and a match controller coordinates global objectives.
- Initialize transient state separately for each instance and player; do not use `Object.create(controller)` to inherit another player's state.

Resolve official components only with names and access methods proven by the project declarations. For every scene system declared as `ISubSystem`, read `common.data` to prove `IScene.findSystem(...)`, then acquire it from the current component with `this.entity.scene.findSystem("ExactSystemClassName")`. Never use `api.<System>.ins`, `<System>.ins`, `getInstance()`, or a module/global singleton shortcut, even if `.data` exposes one or `dist/game.js` uses one internally. Validate the returned system before dereferencing it; if the current scene cannot provide it, log a bounded diagnostic and stop safely instead of falling back to a singleton.

## Lifecycle and cleanup

- Follow Entity ownership above: acquire `const scene = this.entity.scene`, await `scene.createEntity(...)`, and later call `createdEntity.destroy(removeGo)` on the returned entity instance when its owned lifetime ends. Do not bypass the entity system with raw `mw.GameObject.spawn/destroy`; there is no non-entity exception. For overlapping transforms, audio, animation, and character movement, use UGC components exclusively. Do not recover removed engine members through `entity.gameObject`, derived types, casts, or old engine examples. Engine value types and required object-identity parameters remain usable. Report a capability gap when no UGC equivalent exists rather than inventing one.
- Acquire dependencies, validate configuration, and bind listeners during the declared initialization hook without duplicate initialization.
- Retain every external callback, subscription, timer, or task handle needed for cleanup.
- In Deactivated, remove listeners and stop timers/tasks for the availability period. Reuse the same idempotent cleanup in Destroy as final fallback; returning to edit mode is not destruction.
- Cleanup must be repeatable and safe after partial initialization.
- Prefer events and timers. Do not perform unbounded component/system discovery, attachment, or logging every update tick.
- Any declaration-proven asynchronous readiness retry must be low-frequency, bounded, and stop on success, terminal failure, or attempt exhaustion.

## Common syntax

### Managed editing regions

Put helper methods in `@uc:logic` and business bodies in the matching `@uc:lifecycle-body` or `@uc:func-body` regions. Preserve markers, component IDs, exports, argument slots and generated `try/finally` dispatch. Do not dispatch lifecycle events twice or rewrite managed decorators. Component source is JavaScript; do not insert TypeScript assertions. Declare only hooks required by the behavior.

### Listener example

These are method fragments, not a replacement class. Put lifecycle bodies in their managed regions and helpers in the logic region. Verify `TouchDetectorComponent.onEnterDelegate` and its owner/callback signatures in the current declarations. The same event source, owner and function reference are used for removal.

```js
onComponentAwaked() {
    this._detectorRef = null;
}

onComponentActivated() {
    this.bindDetector();
}

onComponentStarted() {
    this.bindDetector(); // Retry once if dependencies were unavailable at activation.
}

bindDetector() {
    if (!mw.SystemUtil.isServer() || this._detectorRef?.deref()) return;
    const detector = this.entity.getComponent("TouchDetectorComponent");
    if (!detector) {
        this.warn("Missing TouchDetectorComponent");
        return;
    }
    this._detectorRef = new WeakRef(detector);
    detector.onEnterDelegate.add(this, this.onEntityEntered);
}

onEntityEntered(otherEntity) {
    if (!otherEntity || !this._detectorRef?.deref()) return;
    this.log("Entity entered", otherEntity.gameObjectId);
}

onComponentDeactivated() {
    this.releaseListeners();
}

onComponentDestroy() {
    this.releaseListeners();
}

releaseListeners() {
    const detector = this._detectorRef?.deref();
    if (detector) detector.onEnterDelegate.remove(this, this.onEntityEntered);
    this._detectorRef = null;
}
```

### Custom event example

```js
exports.events = [
    { name: "Collected", displayName: "Collected", params: [{ name: "itemId", type: "String" }] }
];

// Emit from a business method; argument order matches params.
this.entity.emit("Collected", itemId);
```

Use unique event identifiers, excluding lifecycle names. Listener wiring belongs to the entity instance panel. `entity.emit` is a local event mechanism, not a network broadcast or durable state synchronization.

### RPC declaration example

This is a fragment of Authoring `replace`, not a complete request. Verify the chosen entrypoint's schema; SideAPI uses `remote_call` instead of `remoteCall` as described above.

```json
{
    "properties": [{ "name": "opened", "type": "Boolean", "replicated": true }],
    "functions": [{
        "name": "requestStatus",
        "code": "requestStatus() { if (!mw.SystemUtil.isServer()) return; this.log('Server received status query'); }",
        "remoteCall": "server"
    }]
}
```

The client calls `this.requestStatus()`. Access exposed properties by the internal field names returned for the actual component, rather than assuming display names are fields.

## Network state ownership

```js
if (mw.SystemUtil.isServer()) {
    // Validate the request and update authoritative state.
}
if (mw.SystemUtil.isClient()) {
    // Render synchronized state in UI and models.
}
```

- Keep endpoint checks independent: both can be true. Clients submit intent; the server validates authenticated caller identity, distance, phase, resources and request frequency. Never trust a client-supplied player ID as identity. Duplicate claim, spend or reward requests must take effect at most once.
- Doors, chests and repair progress need durable synchronized state so late joiners and reconnecting clients can restore appearance and collision. One-shot effects alone cannot restore state.
- Initialize, load and save each player's state independently. For custom snapshots, reject stale match/sequence data and apply after entity readiness; admission-ticket expiry must not stop synchronization for an established match.
- Keep rendering repeatable from state. Validate multiple instances, repeated activation and cleanup, two players competing for one reward, and late-join/reconnect restoration. Distinguish static checks, mocks and actual multiplayer results.

## Logging and runtime evidence

`UserComponentRuntimeBase` provides `this.log(...)`, `this.warn(...)`, and `this.error(...)`. Use those declared methods directly; do not create replacement log functions or look up `LogSystem`.

Runtime logs are buffered while playing. When runtime verification is needed, ask the user to trigger the path and return to edit mode. Only after edit mode is confirmed, read `DataFile/demoLogFile.data` directly when it is inside the verified current UGC workspace. Otherwise use `inspect(projection="runtime_logs")`, or `code.read_project_source` when the editor exposes the persisted project log as source. A log proves that execution reached that record point, not that the whole gameplay outcome completed.

Log bounded scalar values or explicitly formatted summaries. Never log secrets, complete objects, or unbounded payloads, and never emit logs directly from every update tick.

## MCP write and verification sequence

1. Use Authoring Search/Doc to discover the public creation, read, write, lint, and attachment entrypoints. Only after an exact Authoring gap may a captured `code` or `preset` Catalog lookup/invocation run through `authoring_route_fallback`.
2. Create a component only for a new responsibility. Accept only the editor-generated `class_id`. If the result is uncertain, reconcile with `inspect(projection="user_components")` before considering another create.
3. Before modifying an existing component, call `code.read_component` and preserve declarations or regions outside the requested scope.
4. Lint the proposed code before writing.
5. Use `code.apply_component` for a complete managed declaration replacement or `code.write_component_body` for Agent-owned body regions. Submit one planned component at a time.
6. Treat success as complete only when the write Operation returns `succeeded_verified` with hot reload and exact persisted readback. Use `code.read_component` only for diagnosis or reconciliation of an uncertain response.
7. When the target is a preset root, attach the verified `class_id` with `preset.attach_user_component` and require that Operation's exact presence readback.

Completion requires declaration-backed API usage, bounded responsibilities, symmetric cleanup, lint success, and exact semantic readback from every write.
