# Talkai

**Talk to your coding agents. Get checked results.**

Talkai CLI lets you direct Claude Code, Codex and your dev tools from one conversation, by voice
or text, and shows what was actually checked before you ship. It runs on your computer, next to
your code.

This repository publishes Talkai's releases. Website and documentation:
**[talkailabs.com](https://talkailabs.com)**.

## Install

macOS (Apple Silicon or Intel) or Linux (x86_64 or arm64):

```bash
curl -fsSL https://raw.githubusercontent.com/talkailabs/talkai-releases/main/install.sh | sh
talkai setup
```

The installer downloads the build for your computer from the [latest release](https://github.com/talkailabs/talkai-releases/releases/latest),
checks its SHA-256 checksum and installs `talkai` into `~/.local/bin`. No administrator password
is needed. To read it first: download [`install.sh`](install.sh), read it, then run `sh install.sh`.

**By hand:** download `talkai_<version>_<os>_<arch>.tar.gz` for your machine from the latest
release (`darwin` is macOS; `arm64` is Apple Silicon or ARM, `amd64` is Intel or AMD), then:

```bash
shasum -a 256 -c SHA256SUMS --ignore-missing
tar -xzf talkai_*.tar.gz
sudo install talkai_*/talkai /usr/local/bin/   # or any folder on your PATH
```

**Menu bar app (macOS):** `Talkai_<version>_macOS.zip` on the same page. Use right-click →
Open on first launch until notarization is available.

## New to Talkai?

[Try it in ten minutes](https://talkailabs.com/try/) on a small practice project.

## Problems and ideas

Run `talkai doctor` first. `talkai bug` prepares a redacted report you can read before opening an
[issue](https://github.com/talkailabs/talkai-releases/issues).

## License

Talkai is free to use during the beta under the [usage terms](https://talkailabs.com/terms/).
See [LICENSE](LICENSE). © 2026 Talkai Labs.
