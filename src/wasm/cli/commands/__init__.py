"""CLI commands package for WASM."""

from wasm.cli.commands.webapp import handle_webapp
from wasm.cli.commands.site import handle_site
from wasm.cli.commands.service import handle_service
from wasm.cli.commands.cert import handle_cert

__all__ = ["handle_webapp", "handle_site", "handle_service", "handle_cert"]
