import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

const pluginRootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const hookConfigFile = path.join(pluginRootDir, "hooks/hooks.json");

function readHookCommand(): string {
  const config = JSON.parse(fs.readFileSync(hookConfigFile, "utf-8")) as {
    hooks: { Stop: Array<{ hooks: Array<{ command: string }> }> };
  };
  return config.hooks.Stop[0].hooks[0].command;
}

describe("bundled Stop hook command", () => {
  it("launches the bundle through node so Codex can spawn it on Windows", () => {
    expect(readHookCommand()).toBe('node "${PLUGIN_ROOT}/dist/index.mjs"');
  });

  /**
   * Codex spawns command hooks without a shell, so a `.cmd`/`.bat` shim fails
   * to start and the Stop hook is reported as failed on every turn.
   */
  it("does not route through a batch shim", () => {
    expect(readHookCommand()).not.toContain(".cmd");
    expect(readHookCommand()).not.toContain(".bat");
  });

  it("does not depend on the old marketplace-root relative path", () => {
    expect(readHookCommand()).not.toContain("./plugins/tracing/dist/index.mjs");
  });

  it("uses no shell syntax beyond the placeholder Codex substitutes itself", () => {
    expect(readHookCommand().replaceAll("${PLUGIN_ROOT}", "")).not.toContain("$");
  });

  it("ships no batch shim in the plugin", () => {
    expect(fs.existsSync(path.join(pluginRootDir, "hooks/run.cmd"))).toBe(false);
  });
});
