# WASM - Copilot Instructions

## Project Overview

**WASM (Web App System Management)** is a robust Python CLI tool for deploying and managing web applications on Linux servers. It handles site configuration (Nginx/Apache), SSL certificates (Certbot), systemd services, and automated deployment workflows for various application types.

## Tech Stack

- **Language:** Python 3.10+
- **CLI Framework:** argparse + python-inquirer (interactive mode)
- **Templating:** Jinja2 (for config files)
- **Packaging:** setuptools + debian packaging
- **Testing:** pytest
- **Type Checking:** Type hints throughout

## Project Structure

```
wasm/
├── src/wasm/
│   ├── __init__.py
│   ├── main.py                     # Entry point, CLI router
│   │
│   ├── cli/
│   │   ├── __init__.py
│   │   ├── parser.py               # Argparse configuration
│   │   ├── interactive.py          # Inquirer-based guided mode
│   │   └── commands/
│   │       ├── __init__.py
│   │       ├── webapp.py           # wasm <action> (webapp commands)
│   │       ├── site.py             # wasm site <action>
│   │       ├── service.py          # wasm service <action>
│   │       └── cert.py             # wasm cert <action>
│   │
│   ├── core/
│   │   ├── __init__.py
│   │   ├── config.py               # Global config, paths, defaults
│   │   ├── logger.py               # Custom logger with verbose support
│   │   ├── exceptions.py           # Custom exception hierarchy
│   │   └── utils.py                # Shell commands, file ops, helpers
│   │
│   ├── managers/
│   │   ├── __init__.py
│   │   ├── base_manager.py         # Abstract base for managers
│   │   ├── nginx_manager.py        # Nginx site operations
│   │   ├── apache_manager.py       # Apache site operations
│   │   ├── service_manager.py      # Systemd service operations
│   │   ├── cert_manager.py         # Certbot/SSL operations
│   │   └── source_manager.py       # Git clone, URL fetch
│   │
│   ├── deployers/
│   │   ├── __init__.py
│   │   ├── base.py                 # Abstract BaseDeployer
│   │   ├── registry.py             # Deployer registry & auto-detection
│   │   ├── nextjs.py               # Next.js deployment
│   │   ├── nodejs.py               # Generic Node.js deployment
│   │   ├── vite.py                 # Vite-based apps
│   │   ├── python.py               # Django/Flask/FastAPI
│   │   └── static.py               # Static HTML sites
│   │
│   ├── templates/
│   │   ├── nginx/
│   │   │   ├── proxy.conf.j2       # Reverse proxy template
│   │   │   ├── static.conf.j2      # Static site template
│   │   │   └── ssl.conf.j2         # SSL snippet
│   │   ├── apache/
│   │   │   └── proxy.conf.j2
│   │   └── systemd/
│   │       └── app.service.j2      # Generic service template
│   │
│   └── validators/
│       ├── __init__.py
│       ├── domain.py               # Domain name validation
│       ├── port.py                 # Port availability check
│       └── source.py               # Git URL / path validation
│
├── tests/
├── debian/                         # .deb packaging
├── docs/
├── pyproject.toml
└── Makefile
```

## Coding Conventions

### Python Style

- **PEP 8** compliance, max line length 100
- **Type hints** required for all function signatures
- **Google-style docstrings** for public functions/classes
- **f-strings** for string formatting
- Use **pathlib.Path** instead of os.path
- Prefer **subprocess.run()** with capture_output=True

### Naming

| Element | Convention | Example |
|---------|------------|---------|
| Modules | snake_case | `nginx_manager.py` |
| Classes | PascalCase | `NginxManager` |
| Functions | snake_case | `create_site()` |
| Constants | UPPER_SNAKE | `DEFAULT_APPS_DIR` |
| Private | _prefix | `_run_command()` |

### Imports Order

```python
# Standard library
import os
import subprocess
from pathlib import Path
from typing import Optional, List, Dict

# Third party
import inquirer
from jinja2 import Environment, PackageLoader

# Local
from wasm.core.config import Config
from wasm.core.logger import Logger
from wasm.core.exceptions import WASMError
```

## Key Patterns

### Logger Usage

```python
from wasm.core.logger import Logger

def some_function(verbose: bool = False):
    logger = Logger(verbose=verbose)
    
    logger.step(1, 7, "Cloning repository")      # [1/7] 📥 Cloning repository...
    logger.info("General information")            # Regular info
    logger.debug("Only in verbose mode")          # Shows only with --verbose
    logger.success("Operation completed")         # ✓ Operation completed
    logger.warning("Something to note")           # ⚠ Something to note
    logger.error("Something failed")              # ✗ Something failed
```

### Exception Handling

```python
from wasm.core.exceptions import (
    WASMError,           # Base exception
    ConfigError,         # Configuration issues
    DeploymentError,     # Deployment failures
    ServiceError,        # Systemd service issues
    CertificateError,    # SSL/Certbot issues
    ValidationError,     # Input validation failures
)

# Always use specific exceptions
raise DeploymentError(f"Build failed: {stderr}")
```

### Command Execution

```python
from wasm.core.utils import run_command, run_command_sudo

# Regular command
result = run_command(["npm", "install"], cwd=app_path)
if not result.success:
    raise DeploymentError(result.stderr)

# Command requiring sudo
result = run_command_sudo(["systemctl", "restart", "nginx"])
```

### Manager Pattern

```python
from wasm.managers.base_manager import BaseManager

class NginxManager(BaseManager):
    """Manages Nginx site configurations."""
    
    SITES_AVAILABLE = Path("/etc/nginx/sites-available")
    SITES_ENABLED = Path("/etc/nginx/sites-enabled")
    
    def create_site(self, domain: str, config: dict) -> bool:
        """Create a new Nginx site configuration."""
        # Implementation
    
    def enable_site(self, domain: str) -> bool:
        """Enable a site by creating symlink."""
        # Implementation
    
    def reload(self) -> bool:
        """Reload Nginx configuration."""
        return self._run_sudo(["nginx", "-s", "reload"]).success
```

### Deployer Pattern

```python
from wasm.deployers.base import BaseDeployer

class NextJSDeployer(BaseDeployer):
    """Deployer for Next.js applications."""
    
    APP_TYPE = "nextjs"
    DETECTION_FILES = ["next.config.js", "next.config.mjs", "next.config.ts"]
    
    def detect(self, path: Path) -> bool:
        """Check if path contains a Next.js project."""
        return any((path / f).exists() for f in self.DETECTION_FILES)
    
    def get_install_command(self) -> List[str]:
        return ["npm", "ci"]
    
    def get_build_command(self) -> List[str]:
        return ["npm", "run", "build"]
    
    def get_start_command(self) -> str:
        return "npm run start"
    
    def get_health_check(self) -> str:
        return "/"
```

### Interactive Mode (Inquirer)

```python
import inquirer
from inquirer.themes import GreenPassion

def prompt_webapp_create() -> dict:
    """Interactive prompts for webapp creation."""
    
    questions = [
        inquirer.List(
            "app_type",
            message="Select application type",
            choices=[
                ("Next.js", "nextjs"),
                ("Node.js", "nodejs"),
                ("Vite (React/Vue/Svelte)", "vite"),
                ("Python (Django/Flask/FastAPI)", "python"),
                ("Static Site", "static"),
            ],
        ),
        inquirer.Text(
            "domain",
            message="Enter domain name",
            validate=lambda _, x: validate_domain(x),
        ),
        inquirer.Text(
            "source",
            message="Enter source (Git URL or path)",
            validate=lambda _, x: validate_source(x),
        ),
        inquirer.Text(
            "port",
            message="Enter port number",
            default="3000",
            validate=lambda _, x: validate_port(x),
        ),
        inquirer.Confirm(
            "ssl",
            message="Configure SSL certificate?",
            default=True,
        ),
    ]
    
    return inquirer.prompt(questions, theme=GreenPassion())
```

## CLI Command Structure

```
wasm [--verbose] [--help] [--version]
wasm --interactive

wasm create -d DOMAIN -s SOURCE -t TYPE [-p PORT] [--pm npm|pnpm|bun] [--no-ssl]
wasm list
wasm status DOMAIN
wasm restart DOMAIN
wasm update DOMAIN [-s SOURCE] [-b BRANCH] [--pm npm|pnpm|bun]
wasm delete DOMAIN
wasm logs DOMAIN [--follow] [--lines N]

wasm site create -d DOMAIN [-w nginx|apache]
wasm site list
wasm site enable DOMAIN
wasm site disable DOMAIN
wasm site delete DOMAIN

wasm service create --name NAME --command CMD [--user USER]
wasm service list
wasm service start|stop|restart|status NAME
wasm service logs NAME [--follow] [--lines N]
wasm service delete NAME

wasm cert create -d DOMAIN [--email EMAIL]
wasm cert list
wasm cert renew [--all]
wasm cert info DOMAIN
wasm cert revoke DOMAIN
```

## Configuration Files

### Global Config: `/etc/wasm/config.yaml`

```yaml
apps_directory: /var/www/apps
webserver: nginx
service_user: www-data
ssl:
  enabled: true
  provider: certbot
  email: admin@example.com
```

### Project Config: `.wasm.yaml`

```yaml
type: nextjs
port: 3000
build_command: npm run build
start_command: npm run start
health_check: /api/health
env:
  NODE_ENV: production
```

## Templates (Jinja2)

Templates use `.j2` extension and these variables:

- `{{ domain }}` - Domain name
- `{{ port }}` - Application port
- `{{ app_path }}` - Full path to app directory
- `{{ app_name }}` - Sanitized app name (for service)
- `{{ user }}` - Service user
- `{{ ssl }}` - Boolean, SSL enabled

## Error Handling

- Always catch specific exceptions
- Log errors with context before re-raising
- Provide actionable error messages to users
- Clean up partial changes on failure when possible

## Testing Guidelines

- Unit tests for validators, utils, individual methods
- Integration tests for managers (may need mocking)
- Use pytest fixtures for common setup
- Mock subprocess calls for unit tests

## Important Paths

| Path | Purpose |
|------|---------|
| `/var/www/apps/` | Deployed applications |
| `/etc/wasm/` | Global configuration |
| `/var/log/wasm/` | Application logs |
| `/etc/nginx/sites-available/` | Nginx configs |
| `/etc/systemd/system/` | Service files |

## Dependencies

### Python Packages
- inquirer
- jinja2
- pyyaml
- rich (optional, for better output)

### System Dependencies
- nginx or apache2
- certbot
- git
- nodejs/npm (for JS apps)
- python3-venv (for Python apps)
