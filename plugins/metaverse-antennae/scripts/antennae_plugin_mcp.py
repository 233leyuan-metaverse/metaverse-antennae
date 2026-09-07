"""Metaverse Antennae Codex plugin entrypoint for the standalone MCP runtime."""

from __future__ import annotations

from antennae_core.bootstrap import create_server


def main() -> None:
    create_server().run(transport="stdio")


if __name__ == "__main__":
    main()
