# Verification

Every write needs semantic evidence from the editor.

## Scene objects

Use `inspectSceneObjectDetail` for attached abilities, hierarchy, events, and bindings. Use `inspectPropertyValues` for exact changed property paths. A paginated scene overview proves absence only after every page has been read and the final response reports `complete=true`.

## UI

Use `inspectUiDetail` for properties, bindings, events, and canvas ownership. Use `inspectPropertyValues` for surgical value checks.

For client runtime UI properties, editor/source readback is not runtime evidence. Require the runtime call to complete `query -> schema -> set -> get`, compare `effectiveValue` exactly, and retain the stable result code. A non-client call returns `CLIENT_ONLY`; a JavaScript exception is a different outcome and requires its exact stage. Runtime diagnosis must not mutate the design-time canvas or widgets.

## User components

Before Apply, read `DataFile/userComponent/description/<classId>.data` to establish the positive `componentRevision` and complete managed state, and read `DataFile/userComponent/classes/<classId>.js.mfile` for source. After Apply, read both files again and compare description, properties, fields, functions, lifecycle hooks, events, and source; require the revision to increase. `sideapi_user_component_read`, `inspectUserComponents`, and `inspectUserComponentApi` are intentionally unavailable.

## Ambiguous transport results

A timeout or missing response does not prove failure. Inspect the intended target before retrying. Retry only when readback proves the write did not land and the operation is safe to repeat.

## Completion

Report what changed, the identifiers affected, and the readback that proved the result. Report partial completion or a structured gap when evidence is missing.

Use these completion levels for executable changes:

- `source_installed`: exact UserComponent source/revision/reload readback only.
- `runtime_unverified`: no readable runtime execution evidence, including when only the packaged API declaration is proven.
- `runtime_api_unavailable`: the live singleton or required method is missing.
- `runtime_readback_verified`: runtime set/get or equivalent semantic readback exactly matches the expected value.
- `visual_verified`: runtime readback plus a UGC viewport capture or explicit user visual acceptance.

Do not skip levels. In particular, source installation cannot be reported as runtime or visual success.
