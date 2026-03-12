# Contributing

Contributions are welcome. Please follow the guidelines below.

## Reporting Issues

Open a GitHub issue with:
- A clear description of the problem
- Steps to reproduce
- Expected vs actual behaviour
- OS and relevant tool versions

## Submitting Changes

1. Fork the repository and create a branch from `master`.
2. Make your changes.
3. Test on a Debian/Kali-based system before submitting.
4. Open a pull request with a clear description of what was changed and why.

## Guidelines

### Adding a new tool

- Add the install command to `install.sh` under the appropriate category.
- If the tool can run unattended, add it to `scan.sh`.
- If it requires manual invocation, note this in the README under the relevant section.
- Add it to the tool list in `README.md` with a one-line description.
- Add it to the `TOOLS` dict in `menu.py` under the appropriate category.

### Adding hardening rules

- Hardening logic goes in `harden.sh`, grouped into clearly commented sections.
- Rules must be idempotent (safe to run multiple times).
- Prefer drop-in config files (e.g. `/etc/sysctl.d/`, `/etc/ssh/sshd_config.d/`) over patching system files directly.

### Shell scripts

- POSIX `sh` compatible — no bash-specific syntax.
- 4-space indentation, no tabs.
- All functions `CamelCase`, all variables `ALL_CAPS`.

### Python

- Python 3, standard library only (no third-party dependencies).
- 4-space indentation.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
