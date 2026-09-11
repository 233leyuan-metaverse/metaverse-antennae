import { getConfig } from "./config.js";
import { canExportTraces, setupInstrumentation } from "./instrumentation.js";
import { convertRollout } from "./trace.js";
import type { HookInput } from "./types.js";
import { auditLog, debugLog, readStdin, setDebug } from "./utils.js";

let failOnError = process.env.LANGFUSE_CODEX_FAIL_ON_ERROR === "true";

/**
 * Entry point for the Codex `Stop` hook.
 *
 * Codex pipes a JSON payload to stdin after every turn. We resolve config,
 * bail out unless tracing is explicitly enabled, then convert the rollout
 * transcript into Langfuse traces.
 *
 * The hook fails open: any error is logged (in debug mode) and swallowed so a
 * tracing problem never blocks the Codex session. Set
 * `LANGFUSE_CODEX_FAIL_ON_ERROR=true` while testing if you want Codex to report
 * hook failures instead.
 */
export async function runHook(): Promise<void> {
  let hookInput: HookInput;
  try {
    hookInput = await readStdin<HookInput>();
  } catch (error) {
    auditLog(`skip empty-or-invalid-stdin: ${error instanceof Error ? error.message : "unknown"}`);
    return;
  }

  const config = await getConfig();
  setDebug(config.debug);
  failOnError = config.fail_on_error;
  auditLog(`start transcript=${hookInput.transcript_path ?? ""} enabled=${config.enabled}`);

  if (!config.enabled) {
    debugLog("tracing disabled (set TRACE_TO_LANGFUSE=false to disable)");
    auditLog("skip disabled");
    return;
  }
  if (!canExportTraces(config)) {
    debugLog("missing ingest token or LANGFUSE_PUBLIC_KEY / LANGFUSE_SECRET_KEY; skipping");
    auditLog("skip missing-credentials");
    return;
  }
  if (!hookInput.transcript_path) {
    debugLog("hook payload missing transcript_path; skipping");
    auditLog("skip missing-transcript_path");
    return;
  }

  const instrumentation = setupInstrumentation(config);
  try {
    await convertRollout(hookInput.transcript_path, { config });
    auditLog("convert-ok");
  } catch (error) {
    debugLog("failed to convert rollout:", error);
    auditLog(`convert-error: ${error instanceof Error ? error.message : "unknown"}`);
    if (config.fail_on_error) throw error;
  } finally {
    try {
      await instrumentation.shutdown();
    } catch (error) {
      debugLog("error during flush/shutdown:", error);
      if (config.fail_on_error) throw error;
    }
  }
}

runHook().catch((error) => {
  // Last-resort guard: fail open unless explicitly requested for testing.
  if (process.env.LANGFUSE_CODEX_DEBUG === "true") {
    // eslint-disable-next-line no-console
    console.error("[langfuse-codex] fatal:", error);
  }
  if (failOnError) {
    process.exitCode = 1;
  }
});
