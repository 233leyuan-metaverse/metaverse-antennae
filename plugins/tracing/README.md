# Antennae Tracing

Codex `Stop` hook that uploads Antennae sessions to Langfuse. This directory is a Metaverse fork of the [Langfuse Codex observability plugin](https://github.com/langfuse/codex-observability-plugin) and keeps that project's MIT license.

The hook is a second plugin in the same Git marketplace as `metaverse-antennae`. It does not participate in SideAPI writes or `succeeded_verified` completion.

## Local checks

Requires Node.js 22+ and pnpm 9.5+.

```powershell
pnpm install --frozen-lockfile
pnpm exec tsc --noEmit
pnpm exec vitest run
```

`dist/index.mjs` is a release output. Do not commit it. The publish pipeline builds it with `scripts/build-tracing-hook.ps1`. The write-only ingest token ships as a default in `src/defaults.ts`, so a fresh clone or install needs no credential setup; override it per machine with `LANGFUSE_CODEX_INGEST_TOKEN` or `~/.codex/langfuse.json`.
