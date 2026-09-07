/** Shared product defaults for the Metaverse Codex → Langfuse plugin. */

export const DEFAULT_BASE_URL = "https://mw-pheromone-web.meta-verse.co";

/**
 * Write-only ingest token used by the published bundle.
 *
 * Source keeps this empty. `scripts/build-tracing-hook.ps1` injects the token
 * from the gitignored `.data/tracing-ingest.json` into a temporary build copy.
 * Operators can still override it with `LANGFUSE_CODEX_INGEST_TOKEN` or
 * `~/.codex/langfuse.json`.
 */
export const DEFAULT_INGEST_TOKEN = "";

/** Codex MCP config key and FastMCP server name for Antennae. */
export const DEFAULT_REQUIRE_MCP_SERVERS = ["antennae_sideapi", "metaverse-antennae"];
