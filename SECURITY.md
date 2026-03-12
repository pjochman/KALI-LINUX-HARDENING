# Security Policy

## Supported Versions

This project is actively maintained. Security fixes are applied to the latest version on the `master` branch.

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please **do not open a public GitHub issue**.

Instead, report it privately by emailing the maintainer or using GitHub's private vulnerability reporting feature:
- GitHub: navigate to the **Security** tab of this repository and click **Report a vulnerability**

Please include:
- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fix (optional)

You can expect an acknowledgement within **48 hours** and a resolution or status update within **7 days**.

## Scope

This policy covers vulnerabilities in:
- `install.sh` — package installation and third-party download logic
- `scan.sh` — tool invocation and output handling
- `harden.sh` — system configuration changes
- `menu.py` — user interface and command execution
- `util/` — Python utilities

## Out of Scope

- Vulnerabilities in the third-party tools installed by this project (report those upstream)
- Issues arising from misconfiguration outside this project
- Social engineering

## Responsible Disclosure

We ask that you give us reasonable time to address the issue before any public disclosure. We will credit researchers who report valid vulnerabilities if they wish.

## Intended Use

This project is intended for **defensive security and authorised system hardening only**. Any use of this project against systems without explicit permission is outside the scope of this policy and is illegal.
