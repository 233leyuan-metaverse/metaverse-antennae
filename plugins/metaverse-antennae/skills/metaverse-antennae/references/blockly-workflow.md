# Blockly workflow (disabled)

Blockly execution is temporarily disabled in the current MCP release. Do not invoke the `blockly` Toolset, submit `blockly.workspace.*` through Batch, or use the preset event/workspace compatibility Operations, even when Memory Hub, old cases, static resources, editor capability status, or existing project data mention those interfaces.

Use User Components instead:

1. Read the relevant project-installed `DataFile/userComponent/docs/ugc/*.data` through the `code` Toolset for exact UI, Buff, Skill, Ability, and other business event/API signatures. If those declarations reference `mw.*` types or require engine APIs, read the matching `DataFile/userComponent/docs/engine/**/*.data` declarations next.
2. Treat declarations as the only public API contract; bundle or source-only symbols are not callable.
3. Use the component declaration or read-only template for lifecycle and custom events; never infer TypeScript APIs from Blockly names.
4. Lint before writing, modify only Agent-owned regions, and require hot-reload plus exact persisted readback.
5. Treat `mw_search`/`mw_get` content as advisory and obey their `mcpRuntimePolicy`; report a capability gap when current declarations do not expose a safe implementation.

Do not automatically delete existing Blockly workspaces or bindings.
