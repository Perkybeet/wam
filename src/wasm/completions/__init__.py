"""
Shell completions for WASM CLI.
"""

from pathlib import Path

COMPLETIONS_DIR = Path(__file__).parent


def get_bash_completion() -> str:
    """Get bash completion script content."""
    bash_file = COMPLETIONS_DIR / "wasm.bash"
    if bash_file.exists():
        return bash_file.read_text()
    return ""


def get_zsh_completion() -> str:
    """Get zsh completion script content."""
    zsh_file = COMPLETIONS_DIR / "_wasm"
    if zsh_file.exists():
        return zsh_file.read_text()
    return ""


def get_fish_completion() -> str:
    """Get fish completion script content."""
    fish_file = COMPLETIONS_DIR / "wasm.fish"
    if fish_file.exists():
        return fish_file.read_text()
    return ""
