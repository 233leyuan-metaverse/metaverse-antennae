# Blockly workflow (disabled)

Blockly execution is temporarily disabled in the current MCP release. Do not invoke the `blockly` Toolset, submit `blockly.workspace.*` through Batch, or use the preset event/workspace compatibility Operations, even when Memory Hub, old cases, static resources, editor capability status, or existing project data mention those interfaces.

Use User Components instead:

1. Inspect `projection="user_component_api"` to read the bindings actually injected into User Component code.
2. Read the relevant project-installed `.d.ts` through the `code` Toolset for exact UI, Buff, Skill, Ability, and other event/API signatures.
3. Use the component declaration or read-only template for lifecycle and custom events; never infer TypeScript APIs from Blockly names.
4. Lint before writing, modify only Agent-owned regions, and require hot-reload plus exact persisted readback.
5. Treat `mw_search`/`mw_get` content as advisory and obey their `mcpRuntimePolicy`; report a capability gap when current declarations do not expose a safe implementation.

Do not automatically delete existing Blockly workspaces or bindings.
