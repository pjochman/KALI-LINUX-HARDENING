# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Lynis** is a shell-based security auditing and hardening tool for Unix/Linux systems. It requires no compilation — the main entry point is the `lynis` shell script.

## Running Lynis

```sh
./lynis audit system                        # full system audit
./lynis audit system --profile developer.prf  # debug/developer mode
./lynis show help                           # show all commands
```

## Syntax Checking

```sh
sh -n lynis                        # check main script for syntax errors
sh -n include/<file>               # check an include file
```

## Architecture

- **`lynis`** — main executable shell script; handles CLI parsing and bootstraps the audit
- **`include/`** — shell function libraries and test modules loaded at runtime:
  - `tests_*` files contain the actual security checks (grouped by category: auth, crypto, filesystems, firewalls, etc.)
  - `functions` — core shared functions (deleted in working tree; normally present)
  - `helper_*` — subcommand handlers (configure, update, generate, etc.)
  - `consts`, `binaries`, `osdetection`, `profiles`, `parameters` — setup/init includes
- **`plugins/`** — optional plugin files (`plugin_*_phase1`) loaded during scan phases; custom plugins go here
- **`db/`** — static data files (OS EOL dates, banners, etc.)
- **`extras/`** — shell completion, build scripts, CI helpers

## Code Conventions

- All code must be **POSIX sh** compatible (`/bin/sh`), not bash-specific
- Indentation: **4 spaces** (no tabs)
- Variables: `ALL_CAPS_WITH_UNDERSCORES`
- Functions: `CamelCase` (to distinguish from shell builtins and external commands)
- Comments: `# ` (hash + space); max one blank line between blocks
- Profile customization goes in `custom.prf`, never in `default.prf`

## Custom util Package

A `util/` Python package was added to this repo with:
- `util/logging.py` — `get_logger(name, level, log_file, fmt, datefmt)` factory
- `util/__init__.py` — makes it a package
