import { describe, expect, it } from "vitest";

import { firstRequiredMcpTurnIndex, turnUsesRequiredMcp } from "../src/mcp-gate.js";
import type { Turn } from "../src/types.js";

function turn(toolCalls: Array<{ name: string; server?: string }>): Turn {
  return {
    startTime: 0,
    endTime: 1,
    steps: [
      {
        startTime: 0,
        endTime: 1,
        toolCalls: toolCalls.map((tc, index) => ({
          callId: `call-${index}`,
          name: tc.name,
          args: {},
          startTime: 0,
          mcp: tc.server
            ? { server: tc.server, tool: tc.name.split("__")[1] ?? tc.name }
            : undefined,
        })),
      },
    ],
    subagentThreadIds: [],
    completed: true,
    aborted: false,
  };
}

const servers = ["antennae_sideapi", "metaverse-antennae"];

describe("mcp gate", () => {
  it("matches invocation.server and mangled server__tool names", () => {
    expect(
      turnUsesRequiredMcp(turn([{ name: "system_status", server: "antennae_sideapi" }]), servers),
    ).toBe(true);
    expect(turnUsesRequiredMcp(turn([{ name: "metaverse-antennae__inspect" }]), servers)).toBe(
      true,
    );
    expect(
      turnUsesRequiredMcp(turn([{ name: "linear__create_issue", server: "linear" }]), servers),
    ).toBe(false);
  });

  it("treats an empty allowlist as no gate", () => {
    expect(turnUsesRequiredMcp(turn([]), [])).toBe(true);
    expect(firstRequiredMcpTurnIndex([turn([]), turn([])], [])).toBe(0);
  });

  it("returns the first matching turn and -1 when none match", () => {
    const idle = turn([]);
    const antennae = turn([{ name: "antennae_sideapi__system_status" }]);
    expect(firstRequiredMcpTurnIndex([idle, antennae], servers)).toBe(1);
    expect(firstRequiredMcpTurnIndex([idle], servers)).toBe(-1);
  });
});
