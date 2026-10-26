#!/bin/sh
# Install Talkai: downloads the right release for this computer, checks its
# SHA-256 checksum and installs `talkai` into ~/.local/bin (no sudo).
#
#   curl -fsSL https://raw.githubusercontent.com/talkailabs/talkai-releases/main/install.sh | sh
#
# Settings (environment variables):
#   TALKAI_VERSION        version to install, e.g. v0.1.0 (default: the latest release)
#   TALKAI_REPO           GitHub repository with the releases (default: talkailabs/talkai-releases)
#   TALKAI_INSTALL_DIR    where to put `talkai` (default: ~/.local/bin)
#   TALKAI_DOWNLOAD_BASE  download from this URL instead of GitHub (mirrors, tests);
#                         needs TALKAI_VERSION
# A private repository needs the GitHub CLI signed in (`gh auth login`) or GITHUB_TOKEN.
set -eu

REPO=${TALKAI_REPO:-talkailabs/talkai-releases}
DIR=${TALKAI_INSTALL_DIR:-$HOME/.local/bin}
BASE=${TALKAI_DOWNLOAD_BASE:-}
VERSION=${TALKAI_VERSION:-}

say() { printf '%s\n' "$*"; }
die() { printf 'talkai install: %s\n' "$*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

case "$(uname -s)" in
Darwin) OS=darwin ;;
Linux) OS=linux ;;
*) die "Talkai supports macOS and Linux for now (this is $(uname -s)). Windows is coming later." ;;
esac
case "$(uname -m)" in
x86_64 | amd64) ARCH=amd64 ;;
arm64 | aarch64) ARCH=arm64 ;;
*) die "unsupported processor $(uname -m); Talkai is built for x86_64 and arm64" ;;
esac
# An x86_64 shell under Rosetta on Apple Silicon: install the native build.
if [ "$OS" = darwin ] && [ "$ARCH" = amd64 ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = 1 ]; then
	ARCH=arm64
fi
has tar || die "tar is required"
if has sha256sum; then SHA="sha256sum"; elif has shasum; then SHA="shasum -a 256"; else die "sha256sum or shasum is required"; fi

gh_ok() { has gh && gh auth status >/dev/null 2>&1; }

api() { # GitHub API GET, with a token if there is one
	if [ -n "${GITHUB_TOKEN:-}" ]; then
		curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/$1"
	else
		curl -fsSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/$1"
	fi
}

if [ -z "$VERSION" ]; then
	[ -z "$BASE" ] || die "TALKAI_DOWNLOAD_BASE needs TALKAI_VERSION"
	VERSION=$(api releases/latest 2>/dev/null | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
	if [ -z "$VERSION" ] && gh_ok; then
		VERSION=$(gh release view --repo "$REPO" --json tagName --jq .tagName 2>/dev/null || true)
	fi
	[ -n "$VERSION" ] || die "couldn't find the latest release of $REPO (a private repository needs \`gh auth login\` or GITHUB_TOKEN)"
fi
V=${VERSION#v}
FILE="talkai_${V}_${OS}_${ARCH}.tar.gz"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

say "Installing Talkai $VERSION ($OS/$ARCH) into $DIR"

fetch() { # fetch NAME: into $TMP/NAME
	if [ -n "$BASE" ]; then
		curl -fsSL -o "$TMP/$1" "$BASE/$1" && return 0
		return 1
	fi
	curl -fsSL -o "$TMP/$1" "https://github.com/$REPO/releases/download/$VERSION/$1" 2>/dev/null && return 0
	if gh_ok; then # private repository
		gh release download "$VERSION" --repo "$REPO" --pattern "$1" --dir "$TMP" --clobber >/dev/null 2>&1 && return 0
	fi
	return 1
}

fetch "$FILE" || die "couldn't download $FILE for $VERSION (is there a release for $OS/$ARCH? a private repository needs \`gh auth login\`)"
fetch SHA256SUMS || die "couldn't download SHA256SUMS for $VERSION"

WANT=$(awk -v f="$FILE" '$2 == f || $2 == "*" f {print $1}' "$TMP/SHA256SUMS")
GOT=$(cd "$TMP" && $SHA "$FILE" | awk '{print $1}')
[ -n "$WANT" ] || die "$FILE isn't listed in SHA256SUMS"
[ "$WANT" = "$GOT" ] || die "checksum mismatch for $FILE (expected $WANT, got $GOT): the download is damaged or was tampered with; nothing was installed"
say "  checksum verified"

tar -xzf "$TMP/$FILE" -C "$TMP"
mkdir -p "$DIR"
# Replace atomically so a running talkai isn't disturbed.
cp "$TMP/talkai_${V}_${OS}_${ARCH}/talkai" "$DIR/.talkai.new"
chmod 755 "$DIR/.talkai.new"
mv -f "$DIR/.talkai.new" "$DIR/talkai"
# macOS: the microphone helper (for `talkai voice`) goes next to talkai.
if [ -f "$TMP/talkai_${V}_${OS}_${ARCH}/talkai-mac" ]; then
	cp "$TMP/talkai_${V}_${OS}_${ARCH}/talkai-mac" "$DIR/.talkai-mac.new"
	chmod 755 "$DIR/.talkai-mac.new"
	mv -f "$DIR/.talkai-mac.new" "$DIR/talkai-mac"
	say "  microphone helper installed (macOS asks for microphone permission the first time you use voice)"
fi
"$DIR/talkai" version >/dev/null 2>&1 || die "the installed talkai doesn't run on this machine"
say "  installed: $("$DIR/talkai" version)"

case ":$PATH:" in
*":$DIR:"*) ;;
*)
	say ""
	say "Add $DIR to your PATH, for example:"
	say "  echo 'export PATH=\"$DIR:\$PATH\"' >> ~/.zshrc   # then open a new terminal"
	;;
esac
say ""
say "Next:"
say "  talkai setup     # choose how Talkai understands you (your Claude/Codex subscription, an API key, or built-in commands)"
say "  talkai doctor    # check this machine"
say "  talkai           # start talking (type, or 'talkai voice')"
if [ "$OS" = darwin ]; then
	say "  Menu bar app: download Talkai_${V}_macOS.zip from https://github.com/$REPO/releases/tag/$VERSION"
fi
