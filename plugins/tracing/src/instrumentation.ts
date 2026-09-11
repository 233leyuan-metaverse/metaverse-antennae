import { LangfuseSpanProcessor } from "@langfuse/otel";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";
import { NodeTracerProvider } from "@opentelemetry/sdk-trace-node";

import type { Config } from "./config.js";

export type Instrumentation = {
  /** Flush buffered spans and tear down the tracer provider. */
  shutdown: () => Promise<void>;
};

function officialKeysConfigured(config: Config): boolean {
  return Boolean(config.public_key && config.secret_key);
}

/** Prefer the write-only ingest token when both auth styles are present. */
export function shouldUseOfficialKeys(config: Config): boolean {
  return officialKeysConfigured(config) && !config.ingest_token;
}

function ingestExporter(config: Config): OTLPTraceExporter {
  const baseUrl = config.base_url.replace(/\/$/, "");
  return new OTLPTraceExporter({
    url: `${baseUrl}/api/public/codex/otel/v1/traces`,
    headers: {
      Authorization: `Bearer ${config.ingest_token}`,
      "x-langfuse-sdk-name": "javascript",
      "x-langfuse-sdk-version": "codex-observability-plugin",
      "x-langfuse-public-key": "codex-ingest",
    },
  });
}

/**
 * Configure an isolated OpenTelemetry tracer provider wired to Langfuse.
 *
 * Official pk/sk pairs still hit `/api/public/otel/v1/traces`. The zero-config
 * path uses a write-only ingest token against `/api/public/codex/otel/v1/traces`.
 */
export function setupInstrumentation(config: Config): Instrumentation {
  const useOfficial = shouldUseOfficialKeys(config);
  const spanProcessor = new LangfuseSpanProcessor({
    publicKey: config.public_key,
    secretKey: config.secret_key,
    baseUrl: config.base_url,
    environment: config.environment,
    exportMode: "batched",
    shouldExportSpan: () => true,
    ...(useOfficial ? {} : { exporter: ingestExporter(config) }),
  });

  const provider = new NodeTracerProvider({
    spanProcessors: [spanProcessor],
  });
  provider.register();

  return {
    shutdown: async () => {
      await spanProcessor.forceFlush();
      await provider.shutdown();
    },
  };
}

export function canExportTraces(config: Config): boolean {
  return officialKeysConfigured(config) || Boolean(config.ingest_token);
}
