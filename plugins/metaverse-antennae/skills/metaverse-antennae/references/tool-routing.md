# Tool routing

Use this order for multi-step Metaverse Antennae tasks.

## Intent preservation

Do not pre-normalize an open-ended creation, design, assembly, or composition request into one Catalog Operation. First load the responsible domain Skills, decompose the original goal, and use intent-level Authoring Search/Doc to discover a composable public workflow. A Catalog result is only an execution candidate. Select or invoke it first only for a closed, explicit business mutation; after an Authoring coverage gap it may serve as the reviewed fallback candidate.

## Authoring-preferred mutations

Every task-facing tool enters one session-scoped Authoring gate before its original handler. The only business-data exception is `asset_search`; `system_status`, `add_user_chat_memory`, and `add_team_experience` are infrastructure exceptions. MWSearch, MWGet, Skill/Catalog discovery, Inspect, Capture, direct tools, executable Catalog, and Batch cannot run first. Their initial call only captures the tool and arguments, and the handler may run once through `authoring_route_fallback` after a proved Authoring gap. On `AUTHORING_ROUTE_REQUIRED`, treat `routing.queries` only as optional, non-exhaustive starting hints; the list may be empty. Search from the original intent with one precise query per independently owned intent. Once an exact callable symbol is found, Doc it once and stop synonymous Search. Compact Doc `pendingTypes` is not a recursive checklist. If the composed public APIs cover the request, execute the smallest bounded body through `authoring_code_execute` and perform exact semantic readback.

Within one current user task, keep a compact evidence set keyed by exact symbol. Exact Search/Doc results may cover later public Authoring mutations only when the editor session, active project and level, requested semantics, and documented symbols remain unchanged, and no declaration-changing operation, timeout, transport uncertainty, or other execution uncertainty occurred. Do not Doc the same symbol twice while that evidence remains valid. Reuse never crosses tasks, turns, restarts, `EDITOR_LEVEL_CHANGED`, active-project changes, or new symbols or semantics. It saves discovery calls only: every mutation still uses its own bounded `authoring_code_execute` and exact semantic readback. A captured fallback route never inherits reused discovery evidence; prove each route's concrete gap independently.

Use `authoring_route_fallback` only when intent-level discovery returned no results or exact dependency-aware Search/Doc evidence proves a concrete missing operation or semantic. The supplied hints are not mandatory and cannot establish or limit the capability boundary. One top-level Doc is not proof that the dependency closure lacks coverage. The route ID is session-scoped and the captured handler is one-shot. Never fall back after `executed=true`, a timeout, transport uncertainty, or an unresolved partial write; reconcile state instead.

## Existing-object edits

When Authoring Search/Doc proves it cannot resolve the required existing-object identity, consume the captured Inspect call through `authoring_route_fallback`. Use `scene_overview` only for unknown identity, keep exact-name discovery bounded, and use returned real IDs. Any subsequent mutation starts its own Authoring route.

## UI work

Discover canvases and widgets with `inspect(projection="ui_tree")` or `inspect(projection="ui_detail", ...)`. Call `catalog_describe(kind="tool", item_id="build_screen", projection="input_only")` for a screen input and specialize `operation/ui.property.bind` by the known source `kind`; read `antennae://ui/schema` only if the requested custom tree needs definitions or multiple node branches absent from that exact description. Read only the needed sections from `antennae://skills/ui/{section}` or `antennae://skills/worldUI/{section}`. Then use `ui_build_screen`, `ui_bind_property`, or the world-mount Catalog operation. Use only returned canvas/widget GUIDs.

## Multi-domain gameplay

Identify the domains that own each requested fact, read only the corresponding needed `antennae://skills/{skill}/index` and `/body` sections, then use `catalog_search` and `catalog_describe` to resolve each exact Tool, Operation, or property. Do not load all declared dependency bodies automatically; load one only when its subflow is requested. For a pending invocation use `projection="input_only"`, plus ordered `selectors` for already-known discriminators such as `projection`, `action`, `kind`, `scope`, or `type`; use `ability_name` for Ability schemas. For a known property path describe that property ID directly; otherwise search within its exact `owner_ability` and request only `id`, `description`, and `valueSchema`. Keep independent actions as independent calls or an explicit `batch_execute`; every write must satisfy its own exact semantic readback.

## Resources

Search `kind="resourceKind"` for primitive geometry. Use `asset_search` for model, character, image, audio, material, action, or effect resources. Select IDs only from returned candidates; never substitute or guess IDs.

## Skills, presets, and data

Use `catalog_search`/`catalog_describe` for skill, preset, data, content, and resource operations. Resolve only the dependencies whose documented subflow applies, plus the real IDs needed by the requested operation; execute those steps in the order specified by the referenced Skill.

## Memory Hub

Use `mw_search`/`mw_get` only after Authoring Search/Doc proves that prior-case context is required and consume each captured call through `authoring_route_fallback`. They are advisory and never establish executable APIs. `add_user_chat_memory` and `add_team_experience` remain infrastructure exceptions. Never supply or infer `user_id`.

At the end of every turn in which this Skill is active, follow the turn-end personal-memory procedure in `SKILL.md`: draft the final response, call `add_user_chat_memory` once with only the current `user` message and that exact `assistant` draft, then send the draft unchanged. Never retry or duplicate this non-idempotent append. Tool unavailability, unresolved editor identity, interruption, timeout, or failure must not block the final response. Personal chat acceptance proves only that the Chat Memory messages were accepted, not that asynchronous personal-experience extraction is complete.

Use `add_team_experience` only for an already successful reusable workflow with paired tool evidence; `queued` proves only that Skill extraction was scheduled.

## Runtime diagnosis

Use `inspect(projection="runtime_logs")`, `inspect(projection="user_components")`, and `code.read_component` when those facts are relevant. Use the code project-source tools with `pattern="*.data"` to read the current project's `DataFile/userComponent/docs/**/*.data`, the sole public User Component API contract. Search `docs/ugc` first and `docs/engine` second for referenced `mw.*` types or engine-level APIs. Exact `dist/game.js` reads are a last-resort diagnostic only. Diagnose without writing unless the user requested repair. Blockly workspaces are intentionally unavailable through this MCP release; repair or replace runtime logic through User Components using declared event APIs.
