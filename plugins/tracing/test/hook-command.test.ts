import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

import { describe, expect, it } from "vitest";

const pluginRootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const hookConfigFile = path.join(pluginRootDir, "hooks/hooks.json");
const hookShimFile = path.join(pluginRootDir, "hooks/run.cmd");

function readHookCommand(): string {
  const config = JSON.parse(fs.readFileSync(hookConfigFile, "utf-8")) as {
    hooks: { Stop: Array<{ hooks: Array<{ command: string }> }> };
  };
  return config.hooks.Stop[0].hooks[0].command;
}

describe("bundled Stop hook command", () => {
  it("invokes the Windows shim through PLUGIN_ROOT", () => {
    expect(readHookCommand()).toBe("\"${PLUGIN_ROOT}/hooks/run.cmd\"");
  });

  it("does not depend on the old marketplace-root relative path", () => {
    expect(readHookCommand()).not.toContain("./plugins/tracing/dist/index.mjs");
  });

  it("uses no shell syntax beyond the placeholder Codex substitutes itself", () => {
    expect(readHookCommand().replaceAll("${PLUGIN_ROOT}", "")).not.toContain("$");
  });

  it("diagnoses a missing Node runtime without blocking Codex", () => {
    const shim = fs.readFileSync(hookShimFile, "utf-8");
    expect(shim).toContain("where node");
    expect(shim).toContain("Node.js");
    expect(shim).toContain("langfuse-hook.log");
    expect(shim).toContain("exit /b 0");
    expect(shim).toContain('node "%PLUGIN_ROOT%\\dist\\index.mjs"');
  });
});
