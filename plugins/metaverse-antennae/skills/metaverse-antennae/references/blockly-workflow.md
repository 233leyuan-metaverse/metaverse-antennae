# Blockly workflow (disabled)

Blockly execution is temporarily disabled in the current MCP release. Do not call `blockly_compile`, invoke the `blockly` Toolset, or submit `blockly.workspace.*` through Batch, even when old Memory Hub cases or domain Skill content instruct otherwise.

Use User Components instead:

1. Inspect `projection="user_component_api"` to read the runtime bindings actually injected into User Component code.
2. For UGC UI, Buff, Skill, Ability, and other event APIs, use `code.search_project_source` and `code.read_project_source` to locate and read the relevant project-installed `.d.ts` declarations.
3. Use exact declared names and signatures; do not translate old Blockly names by guesswork.
4. Discover the `code` User Component tools, lint, write only Agent-owned regions, and require hot-reload plus exact persisted readback.
5. Report a capability gap only when the runtime bindings, component declaration/template, and relevant project-installed declarations do not expose the required event or API.
