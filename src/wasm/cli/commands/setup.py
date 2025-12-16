"""
Setup command handlers for WASM - initial setup, completions, permissions.
"""

import os
import sys
import shutil
from argparse import Namespace
from pathlib import Path

from wasm.core.logger import Logger
from wasm.core.exceptions import WASMError
from wasm.core.config import DEFAULT_APPS_DIR, DEFAULT_LOG_DIR, DEFAULT_CONFIG_PATH


def handle_setup(args: Namespace) -> int:
    """
    Handle setup commands.
    
    Args:
        args: Parsed arguments.
        
    Returns:
        Exit code.
    """
    action = args.action
    
    handlers = {
        "completions": _handle_completions,
        "init": _handle_init,
        "permissions": _handle_permissions,
    }
    
    handler = handlers.get(action)
    if not handler:
        print(f"Unknown action: {action}", file=sys.stderr)
        return 1
    
    try:
        return handler(args)
    except WASMError as e:
        logger = Logger(verbose=args.verbose)
        logger.error(str(e))
        return 1
    except Exception as e:
        logger = Logger(verbose=args.verbose)
        logger.error(f"Unexpected error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


def _handle_completions(args: Namespace) -> int:
    """Handle completions setup command."""
    logger = Logger(verbose=args.verbose)
    shell = args.shell
    
    # Auto-detect shell if not specified
    if not shell:
        shell = _detect_shell()
        if not shell:
            logger.error("Could not detect shell. Please specify with --shell")
            return 1
    
    logger.header("WASM Shell Completions Setup")
    logger.key_value("Shell", shell)
    logger.blank()
    
    # Get completion script path (from cli/commands/ up to wasm/completions/)
    completions_dir = Path(__file__).parent.parent.parent / "completions"
    
    if shell == "bash":
        return _install_bash_completions(logger, completions_dir, args.user_only)
    elif shell == "zsh":
        return _install_zsh_completions(logger, completions_dir, args.user_only)
    elif shell == "fish":
        return _install_fish_completions(logger, completions_dir, args.user_only)
    else:
        logger.error(f"Unsupported shell: {shell}")
        return 1


def _detect_shell() -> str | None:
    """Detect the current shell."""
    shell_path = os.environ.get("SHELL", "")
    if "bash" in shell_path:
        return "bash"
    elif "zsh" in shell_path:
        return "zsh"
    elif "fish" in shell_path:
        return "fish"
    return None


def _install_bash_completions(logger: Logger, completions_dir: Path, user_only: bool) -> int:
    """Install bash completions."""
    source_file = completions_dir / "wasm.bash"
    
    if not source_file.exists():
        logger.error("Bash completion script not found")
        return 1
    
    if user_only:
        # User-local installation
        target_dir = Path.home() / ".local" / "share" / "bash-completion" / "completions"
        target_file = target_dir / "wasm"
    else:
        # System-wide installation (requires root)
        target_dir = Path("/etc/bash_completion.d")
        target_file = target_dir / "wasm"
        
        if os.geteuid() != 0:
            logger.error("System-wide installation requires root privileges")
            logger.info("Use --user-only for user-local installation, or run with sudo")
            return 1
    
    try:
        target_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(source_file, target_file)
        logger.success(f"Installed bash completions to {target_file}")
        logger.info("Restart your shell or run: source ~/.bashrc")
        return 0
    except PermissionError:
        logger.error(f"Permission denied writing to {target_file}")
        logger.info("Try running with sudo or use --user-only")
        return 1


def _install_zsh_completions(logger: Logger, completions_dir: Path, user_only: bool) -> int:
    """Install zsh completions."""
    source_file = completions_dir / "_wasm"
    
    if not source_file.exists():
        logger.error("Zsh completion script not found")
        return 1
    
    if user_only:
        # User-local installation
        target_dir = Path.home() / ".zsh" / "completions"
        target_file = target_dir / "_wasm"
        fpath_hint = 'Add to .zshrc: fpath=(~/.zsh/completions $fpath)'
    else:
        # System-wide installation (requires root)
        target_dir = Path("/usr/share/zsh/site-functions")
        if not target_dir.exists():
            target_dir = Path("/usr/local/share/zsh/site-functions")
        target_file = target_dir / "_wasm"
        fpath_hint = None
        
        if os.geteuid() != 0:
            logger.error("System-wide installation requires root privileges")
            logger.info("Use --user-only for user-local installation, or run with sudo")
            return 1
    
    try:
        target_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(source_file, target_file)
        logger.success(f"Installed zsh completions to {target_file}")
        if fpath_hint:
            logger.info(fpath_hint)
        logger.info("Run: autoload -Uz compinit && compinit")
        return 0
    except PermissionError:
        logger.error(f"Permission denied writing to {target_file}")
        logger.info("Try running with sudo or use --user-only")
        return 1


def _install_fish_completions(logger: Logger, completions_dir: Path, user_only: bool) -> int:
    """Install fish completions."""
    source_file = completions_dir / "wasm.fish"
    
    if not source_file.exists():
        logger.error("Fish completion script not found")
        return 1
    
    if user_only:
        # User-local installation
        target_dir = Path.home() / ".config" / "fish" / "completions"
        target_file = target_dir / "wasm.fish"
    else:
        # System-wide installation (requires root)
        target_dir = Path("/usr/share/fish/vendor_completions.d")
        target_file = target_dir / "wasm.fish"
        
        if os.geteuid() != 0:
            logger.error("System-wide installation requires root privileges")
            logger.info("Use --user-only for user-local installation, or run with sudo")
            return 1
    
    try:
        target_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy(source_file, target_file)
        logger.success(f"Installed fish completions to {target_file}")
        logger.info("Completions should work immediately or run: exec fish")
        return 0
    except PermissionError:
        logger.error(f"Permission denied writing to {target_file}")
        logger.info("Try running with sudo or use --user-only")
        return 1


def _handle_init(args: Namespace) -> int:
    """Handle initial system setup."""
    logger = Logger(verbose=args.verbose)
    
    # Check for root
    if os.geteuid() != 0:
        logger.error("Initial setup requires root privileges")
        logger.info("Run: sudo wasm setup init")
        return 1
    
    logger.header("WASM Initial Setup")
    logger.blank()
    
    steps_total = 4
    step = 1
    
    # Create apps directory
    logger.step(step, steps_total, f"Creating apps directory: {DEFAULT_APPS_DIR}")
    try:
        DEFAULT_APPS_DIR.mkdir(parents=True, exist_ok=True)
        os.chmod(DEFAULT_APPS_DIR, 0o755)
        logger.success(f"Created {DEFAULT_APPS_DIR}")
    except Exception as e:
        logger.error(f"Failed to create apps directory: {e}")
        return 1
    step += 1
    
    # Create log directory
    logger.step(step, steps_total, f"Creating log directory: {DEFAULT_LOG_DIR}")
    try:
        DEFAULT_LOG_DIR.mkdir(parents=True, exist_ok=True)
        os.chmod(DEFAULT_LOG_DIR, 0o755)
        logger.success(f"Created {DEFAULT_LOG_DIR}")
    except Exception as e:
        logger.error(f"Failed to create log directory: {e}")
        return 1
    step += 1
    
    # Create config directory
    config_dir = DEFAULT_CONFIG_PATH.parent
    logger.step(step, steps_total, f"Creating config directory: {config_dir}")
    try:
        config_dir.mkdir(parents=True, exist_ok=True)
        os.chmod(config_dir, 0o755)
        logger.success(f"Created {config_dir}")
    except Exception as e:
        logger.error(f"Failed to create config directory: {e}")
        return 1
    step += 1
    
    # Create default config if it doesn't exist
    logger.step(step, steps_total, "Creating default configuration")
    if not DEFAULT_CONFIG_PATH.exists():
        try:
            from wasm.core.config import Config
            config = Config()
            config.save()
            logger.success(f"Created {DEFAULT_CONFIG_PATH}")
        except Exception as e:
            logger.warning(f"Could not create config file: {e}")
    else:
        logger.info(f"Config file already exists: {DEFAULT_CONFIG_PATH}")
    
    logger.blank()
    logger.success("WASM setup completed!")
    logger.info("You can now use wasm to deploy applications")
    logger.info("Install shell completions with: wasm setup completions")
    
    return 0


def _handle_permissions(args: Namespace) -> int:
    """Handle permissions check and fix."""
    logger = Logger(verbose=args.verbose)
    
    logger.header("WASM Permissions Check")
    logger.blank()
    
    issues = []
    
    # Check apps directory
    if DEFAULT_APPS_DIR.exists():
        if os.access(DEFAULT_APPS_DIR, os.W_OK):
            logger.success(f"Apps directory writable: {DEFAULT_APPS_DIR}")
        else:
            logger.warning(f"Apps directory not writable: {DEFAULT_APPS_DIR}")
            issues.append(("apps_dir", DEFAULT_APPS_DIR))
    else:
        logger.warning(f"Apps directory does not exist: {DEFAULT_APPS_DIR}")
        issues.append(("apps_dir_missing", DEFAULT_APPS_DIR))
    
    # Check log directory
    if DEFAULT_LOG_DIR.exists():
        if os.access(DEFAULT_LOG_DIR, os.W_OK):
            logger.success(f"Log directory writable: {DEFAULT_LOG_DIR}")
        else:
            logger.warning(f"Log directory not writable: {DEFAULT_LOG_DIR}")
            issues.append(("log_dir", DEFAULT_LOG_DIR))
    else:
        logger.warning(f"Log directory does not exist: {DEFAULT_LOG_DIR}")
        issues.append(("log_dir_missing", DEFAULT_LOG_DIR))
    
    # Check config
    config_dir = DEFAULT_CONFIG_PATH.parent
    if config_dir.exists():
        if os.access(config_dir, os.R_OK):
            logger.success(f"Config directory readable: {config_dir}")
        else:
            logger.warning(f"Config directory not readable: {config_dir}")
            issues.append(("config_dir", config_dir))
    
    # Check nginx/apache access
    nginx_available = Path("/etc/nginx/sites-available")
    if nginx_available.exists():
        if os.access(nginx_available, os.W_OK):
            logger.success(f"Nginx sites-available writable")
        else:
            logger.info(f"Nginx sites-available requires sudo")
    
    # Check systemd access
    systemd_dir = Path("/etc/systemd/system")
    if systemd_dir.exists():
        if os.access(systemd_dir, os.W_OK):
            logger.success(f"Systemd directory writable")
        else:
            logger.info(f"Systemd directory requires sudo")
    
    logger.blank()
    
    if issues:
        logger.warning("Some directories need to be created or have permissions fixed")
        logger.info("Run: sudo wasm setup init")
    else:
        logger.success("All permissions OK!")
        logger.info("Note: Operations that modify nginx/systemd still require sudo")
    
    return 0
