"""CLI module for WASM."""

from wasm.cli.parser import create_parser, parse_args
from wasm.cli.interactive import InteractiveMode

__all__ = ["create_parser", "parse_args", "InteractiveMode"]
