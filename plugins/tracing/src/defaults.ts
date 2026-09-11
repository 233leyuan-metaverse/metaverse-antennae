/** Shared product defaults for the Metaverse Codex → Langfuse plugin. */

export const DEFAULT_BASE_URL = "https://mw-pheromone-web.meta-verse.co";

/**
 * Write-only ingest token for the Codex ingest route of the Metaverse Langfuse
 * project. It grants no read access and cannot reach any other project, and the
 * published bundle ships it to every user anyway, so it lives here instead of
 * being injected at release. Rotating it means editing this line and releasing
 * a new tracing plugin version. Operators can override it per machine with
 * `LANGFUSE_CODEX_INGEST_TOKEN` or `~/.codex/langfuse.json`.
 */
export const DEFAULT_INGEST_TOKEN = "lf-codex-mw-pheromone-ingest-v1";

/** Codex MCP config key and FastMCP server name for Antennae. */
export const DEFAULT_REQUIRE_MCP_SERVERS = ["antennae_sideapi", "metaverse-antennae"];
