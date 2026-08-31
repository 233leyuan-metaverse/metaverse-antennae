"""Buildmode Codex plugin MCP entrypoint.

This standalone layer exposes Contract-owned semantic tools and the read-only
knowledge/discovery tools needed to use editor operations correctly. It does
not start Honey's chat, model orchestration, eval, or web application hooks.
"""

from __future__ import annotations

import os
from typing import Any

from apis.basic_models import lookup_basic_model as buildmode_lookup_basic_model
from apis.resource_search import search_asset as buildmode_search_asset
from apis.sideapi_mcp_server import mcp
from apis.sideapi_server import start_server


mcp._mcp_server.instructions = (
    "Operate the Buildmode editor through named Contract semantic tools. "
    "The MCP silently resolves the active project from the editor and synchronizes the packaged CLI after each "
    "WebSocket connection. Inspect status.response.projectInitialization when project bootstrap diagnostics are "
    "needed. Automatic downgrade is intentionally blocked. If it reports UGC_CLI_DOWNGRADE_BLOCKED, show the "
    "exact project path and versions plus the rollback impact. Only after the user explicitly approves, call "
    "project_cli_confirm_downgrade with those exact values and its literal confirmation phrase. "
    "UGC_PROJECT_WORKSPACE_MISMATCH and UGC_PROJECT_WORKSPACE_UNAVAILABLE are advisory workspace diagnostics, not "
    "editor-tool blockers: show the exact workspace.requiredWorkspaceDirectory to the user, but continue semantic "
    "editor operations when the bridge and contract are ready. If "
    "skillActivation.newSessionRequired=true, tell the user to open a new Codex session in the project because "
    "the current session cannot prove newly installed or updated skills were loaded. "
    "Discover live IDs and state with inspect before writing, and verify every write with exact readback. "
    "Project planning and API/skill discovery come from the CLI files installed in the UGC project; the MCP does "
    "not bundle cases, API catalogs, or mechanism routing knowledge. For custom logic, discover and read existing "
    "components from project-local DataFile/userComponent/description/*.data and classes/*.js.mfile. Create new "
    "components with sideapi_user_component_create and write complete managed state with "
    "sideapi_user_component_apply against the latest positive componentRevision. Apply arrays are complete "
    "replacements, so preserve unrelated entries. sideapi_user_component_sync_from_files, "
    "sideapi_user_component_read, inspectUserComponents, and inspectUserComponentApi are intentionally unavailable. "
    "NEW SCENE / TERRAIN / ARCHITECTURE / ENVIRONMENT builds: use three_scene_run with one "
    "ThreeCompat JavaScript source (THREE and scene already in scope). Do NOT call search_asset or "
    "lookup_basic_model first; do NOT assemble the main structure from asset-library GUIDs. Client "
    "frame-splits spawning—do not batch just to avoid hitching. search_asset is only for optional "
    "props/characters/effects AFTER three_scene_run succeeds. "
    "Blockly compilation, workspace maintenance, instruction-list inspection, and script lint are intentionally "
    "not exposed by this MCP. "
    "For gameplay or multi-step requests use the named semantic tools and their schemas directly. If legacy "
    "guidance requires Blockly or direct "
    "InstructionList authoring, do not follow that route; use a user component when the required API is proven, "
    "or report the unsupported gap. Never invent object IDs, resource IDs, paths, event names, API signatures, "
    "or private Legacy envelopes. Use build_ui_screen for editor-native screen or world UI content, then "
    "inspectUiDetail for real canvas and widget GUIDs. For non-scene resource tasks only, use lookup_basic_model "
    "or search_asset for real asset IDs. "
    "If guidance "
    "or readback is missing, report a structured gap instead of guessing. For an ordinary fixed-point spawner, "
    "prefer the named mechanism_create_spawner tool and treat only outcome=succeeded_verified as completion."
)


@mcp.tool(
    name="lookup_basic_model",
    description=(
        "Resolve a primitive geometry name such as Cube, Sphere, or Cylinder to an authoritative Buildmode resGuid. "
        "Use this instead of guessing primitive asset IDs."
    ),
)
def lookup_basic_model(name: str) -> dict[str, Any]:
    return buildmode_lookup_basic_model(name=name)


@mcp.tool(
    name="search_asset",
    description=(
        "Search authoritative non-primitive Buildmode resources and return real candidate IDs. Supported kinds are "
        "model, character, image, audio, material, action, and effect. Select only returned candidates."
    ),
)
def search_asset(text_list: list[str], kind: str = "model") -> dict[str, Any]:
    return buildmode_search_asset(text_list=text_list, kind=kind)


def main() -> None:
    start_server(hooks=False)

    transport = os.getenv("MCP_TRANSPORT", "stdio").strip().lower()
    if transport == "streamable-http":
        host = os.getenv("MCP_HOST", "127.0.0.1").strip() or "127.0.0.1"
        port_text = os.getenv("MCP_PORT", "8766").strip()
        try:
            port = int(port_text)
        except ValueError as exc:
            raise ValueError(f"MCP_PORT must be an integer, got {port_text!r}") from exc
        if not 1 <= port <= 65535:
            raise ValueError(f"MCP_PORT must be between 1 and 65535, got {port}")

        mcp.settings.host = host
        mcp.settings.port = port
        mcp.run(transport="streamable-http")
        return

    if transport != "stdio":
        raise ValueError(
            "MCP_TRANSPORT must be 'stdio' or 'streamable-http', "
            f"got {transport!r}"
        )

    mcp.run()


if __name__ == "__main__":
    main()

