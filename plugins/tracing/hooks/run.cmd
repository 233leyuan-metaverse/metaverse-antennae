@echo off
setlocal EnableExtensions
if not defined PLUGIN_ROOT (
  echo [antennae-tracing] PLUGIN_ROOT is not set; skipping Langfuse upload. 1>&2
  exit /b 0
)
where node >nul 2>&1
if errorlevel 1 (
  echo [antennae-tracing] Node.js ^>= 22 is required to upload Codex traces to Langfuse. 1>&2
  echo [antennae-tracing] Install Node.js, then restart Codex, or disable the tracing plugin. 1>&2
  if not exist "%USERPROFILE%\.codex" mkdir "%USERPROFILE%\.codex" >nul 2>&1
  >> "%USERPROFILE%\.codex\langfuse-hook.log" echo %date% %time% Node.js not found; skipped Langfuse upload.
  exit /b 0
)
node "%PLUGIN_ROOT%\dist\index.mjs"
exit /b %ERRORLEVEL%
