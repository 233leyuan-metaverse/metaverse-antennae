import type { ToolCall, Turn } from "./types.js";

/**
 * Codex may persist MCP as `server__tool`, `mcp__server__tool`, or an `exec`
 * script that calls `tools.mcp__server__tool(...)`.
 */
export function extractMcpRef(value: unknown): { server: string; tool: string } | undefined {
  const text = typeof value === "string" ? value : value == null ? "" : JSON.stringify(value);
  const match = text.match(/mcp__([A-Za-z0-9][A-Za-z0-9_-]*)__([A-Za-z0-9_]+)/);
  if (!match) return undefined;
  return { server: match[1], tool: match[2] };
}

function toolMatchesRequiredMcp(tc: ToolCall, servers: Set<string>): boolean {
  if (tc.mcp && servers.has(tc.mcp.server)) return true;
  const hinted = extractMcpRef(tc.name) ?? extractMcpRef(tc.args);
  if (hinted && servers.has(hinted.server)) return true;
  for (const server of servers) {
    if (
      tc.name === server ||
      tc.name.startsWith(`${server}__`) ||
      tc.name.startsWith(`mcp__${server}__`)
    ) {
      return true;
    }
  }
  return false;
}

/** True when this turn called at least one MCP server in the allowlist. */
export function turnUsesRequiredMcp(turn: Turn, servers: string[]): boolean {
  if (servers.length === 0) return true;
  const allow = new Set(servers);
  for (const step of turn.steps) {
    for (const tc of step.toolCalls) {
      if (toolMatchesRequiredMcp(tc, allow)) return true;
    }
  }
  return false;
}

/**
 * Index of the first turn that used a required MCP server.
 * Returns 0 when the allowlist is empty (no gate).
 * Returns -1 when the session never used a required server.
 */
export function firstRequiredMcpTurnIndex(turns: Turn[], servers: string[]): number {
  if (servers.length === 0) return 0;
  return turns.findIndex((turn) => turnUsesRequiredMcp(turn, servers));
}
