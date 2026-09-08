@echo off
setlocal EnableExtensions
set "HOOK_DIR=%~dp0"
set "PLUGIN_HOME=%HOOK_DIR%.."
if defined PLUGIN_ROOT (
  set "PLUGIN_HOME=%PLUGIN_ROOT%"
)
where node >nul 2>&1
if errorlevel 1 (
  echo [antennae-tracing] Node.js ^>= 22 is required to upload Codex traces to Langfuse. 1>&2
  echo [antennae-tracing] Install Node.js, then restart Codex, or disable the tracing plugin. 1>&2
  if not exist "%USERPROFILE%\.codex" mkdir "%USERPROFILE%\.codex" >nul 2>&1
  >> "%USERPROFILE%\.codex\langfuse-hook.log" echo %date% %time% Node.js not found; skipped Langfuse upload.
  exit /b 0
)
if not exist "%PLUGIN_HOME%\dist\index.mjs" (
  echo [antennae-tracing] dist/index.mjs is missing under "%PLUGIN_HOME%"; skipped Langfuse upload. 1>&2
  if not exist "%USERPROFILE%\.codex" mkdir "%USERPROFILE%\.codex" >nul 2>&1
  >> "%USERPROFILE%\.codex\langfuse-hook.log" echo %date% %time% missing dist/index.mjs under %PLUGIN_HOME%; skipped Langfuse upload.
  exit /b 0
)
node "%PLUGIN_HOME%\dist\index.mjs"
exit /b %ERRORLEVEL%
