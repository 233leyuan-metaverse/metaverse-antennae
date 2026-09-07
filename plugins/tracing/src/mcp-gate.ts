import type { ToolCall, Turn } from "./types.js";

function toolMatchesRequiredMcp(tc: ToolCall, servers: Set<string>): boolean {
  if (tc.mcp && servers.has(tc.mcp.server)) return true;
  for (const server of servers) {
    if (tc.name === server || tc.name.startsWith(`${server}__`)) return true;
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
