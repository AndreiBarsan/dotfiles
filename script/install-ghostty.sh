#!/usr/bin/env bash
# Build and install Ghostty for the local user.
#
#   macOS -> Homebrew cask (the official signed universal build).
#   Linux -> build from source with the Zig version the tag requires;
#            installed to ~/.local.
#
# How the Ghostty release is chosen on Linux (future-proof by design):
#
#   1. Tags are discovered live via `git ls-remote` — no hardcoded tag list,
#      so a new Ghostty release never breaks the script.
#   2. Each tag's minimum GTK/libadwaita comes from the COMPATIBILITY table
#      in min_versions_for_tag (the only thing to maintain: add one line per
#      new Ghostty release). Unlisted tags are skipped until verified.
#   3. The required Zig version is read from the tag's own build.zig.zon
#      (.minimum_zig_version); tags that predate that field fall back to 0.13.0.
#   4. gtk4-layer-shell: tags whose build.zig.zon declares it link the distro
#      copy if packaged (e.g. Ubuntu 24.04+), otherwise Ghostty compiles it
#      from source into ~/.local/lib (see fix_rpath).
#   5. OpenGL 3.3 shim (NVIDIA/X11): GTK 4.6 on X11 prefers the EGL backend
#      for GL contexts, and on the NVIDIA proprietary driver that path
#      yields a 3.2 context — Ghostty (needs 3.3) aborts with
#      error.OpenGLOutdated. The GLX backend gives a proper core 3.3
#      context, so the installer ships a tiny LD_PRELOAD shim that makes
#      dlopen("libEGL*") fail; epoxy can't find EGL, GTK falls back to
#      GLX, and Ghostty runs. The launcher (~/.local/bin/ghostty) applies
#      it on X11 only — on Wayland it's a no-op passthrough (see
#      install_gl_shim).
#
# Pin a specific release with GHOSTTY_TAG=vX.Y.Z (skips the compatibility
# check — the build may fail if your GTK is too old).
#
# On a headless Linux box (neither DISPLAY nor WAYLAND_DISPLAY set) the
# script exits early. Override with GHOSTTY_FORCE_LINUX=1.
#
# Like the other install-*.sh scripts here, this is for Debian-based distros
# (it uses apt for the build dependencies).

set -euo pipefail
IFS=$'\n\t'

readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
readonly INSTALL_PREFIX="$HOME/.local"
readonly GHOSTTY_DIR="$PROJECTS/ghostty"
readonly ZIG_ROOT="$PROJECTS/ghostty-zig"

# --- helpers -----------------------------------------------------------------

die() { echo >&2 "$*"; exit "${2:-1}"; }

# True if $1 >= $2 (versions in sort -V order).
version_ge() {
  [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" == "$2" ]]
}

require_projects() {
  [[ -n "$PROJECTS" ]] || die \
    "Please run this script after the basic bootstrap setup, so that " \
    "I know where I should download and build ghostty." 10
  [[ -d "$PROJECTS" ]] || die \
    "The projects directory [$PROJECTS] does not exist. Not creating " \
    "by default, since it's a sign that this script is being called at an " \
    "inappropriate time." 20
}

# --- macOS -------------------------------------------------------------------

install_macos() {
  command -v brew >/dev/null 2>&1 || die "Homebrew not found; please install it first." 30
  if brew list --cask ghostty >/dev/null 2>&1; then
    brew upgrade --cask ghostty
  else
    brew install --cask ghostty
  fi
}

# --- Linux -------------------------------------------------------------------

check_headless() {
  if [[ -z "${GHOSTTY_FORCE_LINUX:-}" && -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "No display detected (DISPLAY and WAYLAND_DISPLAY both unset); " \
         "assuming a headless machine and skipping Ghostty."
    exit 0
  fi
}

# Install a list of apt packages, skipping the ones already installed so the
# script is re-runnable without a TTY (sudo needs a password) once deps exist.
apt_install_missing() {
  local missing=() pkg
  for pkg in "$@"; do
    dpkg-query --showformat='${Status}' -W "$pkg" 2>/dev/null \
      | grep -q '^install ok installed' || missing+=("$pkg")
  done

  if (( ${#missing[@]} > 0 )); then
    echo "Installing missing build dependencies:"
    printf '  %s\n' "${missing[@]}"
    sudo apt install --yes --no-install-recommends "${missing[@]}"
  else
    echo "Build dependencies already installed; skipping apt."
  fi
}

install_build_deps() {
  apt_install_missing \
    pkg-config gettext patchelf \
    libgtk-4-dev libadwaita-1-dev
}

# The only datum this script must maintain: minimum GTK/libadwaita per
# Ghostty release (Ghostty doesn't declare these machine-readably).
# Append one line per new release; unlisted tags are treated as unverified
# and skipped by the auto-selection (still usable via GHOSTTY_TAG).
min_versions_for_tag() {
  case "$1" in
    v1.0.*) echo "4.6 1.1" ;;
    v1.1.*) echo "4.8 1.2" ;;
    v1.2.*) echo "4.14 1.5" ;;
    v1.3.*) echo "4.14 1.5" ;;
    v1.4.*) echo "4.18 1.7" ;;
    *)      echo "" ;;
  esac
}

# Ghostty release tags, newest first (skips vt-* and prerelease tags).
list_remote_tags() {
  git ls-remote --tags "$GHOSTTY_REPO" \
    | awk '{sub(/^refs\/tags\//, "", $2); if ($2 ~ /^v[0-9]+\.[0-9]+\.[0-9]+$/) print $2}' \
    | sort -Vru
}

# Pick the newest Ghostty tag whose GTK/libadwaita minimums the system meets.
select_ghostty_tag() {
  if [[ -n "${GHOSTTY_TAG:-}" ]]; then
    echo "Using explicitly requested Ghostty tag [$GHOSTTY_TAG]"
    return 0
  fi

  local gtk ada tag mins min_gtk min_ada
  gtk="$(pkg-config --modversion gtk4)" || die "gtk4 not found in pkg-config; is libgtk-4-dev installed?" 40
  ada="$(pkg-config --modversion libadwaita-1)" || die "libadwaita-1 not found in pkg-config; is libadwaita-1-dev installed?" 40

  while IFS= read -r tag; do
    mins="$(min_versions_for_tag "$tag")"
    [[ -n "$mins" ]] || continue   # unverified tag; keep looking
    read -r min_gtk min_ada <<<"$mins"
    if version_ge "$gtk" "$min_gtk" && version_ge "$ada" "$min_ada"; then
      GHOSTTY_TAG="$tag"
      echo "System GTK [$gtk] / libadwaita [$ada] -> Ghostty [$GHOSTTY_TAG]"
      return 0
    fi
  done < <(list_remote_tags)

  die "System GTK [$gtk] / libadwaita [$ada] is too old for any known Ghostty release." 41
}

# Clone/fetch the chosen tag and check it out. Fetches only that tag, and
# only if it isn't already present locally (re-runs stay offline).
ensure_source() {
  if [[ ! -d "$GHOSTTY_DIR/.git" ]]; then
    git clone "$GHOSTTY_REPO" "$GHOSTTY_DIR"
  fi
  if ! git -C "$GHOSTTY_DIR" rev-parse -q --verify "refs/tags/$GHOSTTY_TAG" >/dev/null; then
    git -C "$GHOSTTY_DIR" fetch --depth 1 origin \
      "refs/tags/$GHOSTTY_TAG:refs/tags/$GHOSTTY_TAG" \
      || die "Ghostty tag [$GHOSTTY_TAG] not found on the remote." 42
  fi
  git -C "$GHOSTTY_DIR" checkout -q "$GHOSTTY_TAG"
}

# Ghostty >= v1.3.1 declares its minimum Zig in build.zig.zon; older tags
# build with Zig 0.13.x, which is the fallback.
resolve_zig_version() {
  local zig
  zig="$(git -C "$GHOSTTY_DIR" show "$GHOSTTY_TAG:build.zig.zon" \
    | sed -n 's/.*\.minimum_zig_version = "\([0-9.]*\)".*/\1/p' | head -n1)" || zig=""
  ZIG_VERSION="${zig:-0.13.0}"
  echo "Ghostty [$GHOSTTY_TAG] -> Zig [$ZIG_VERSION]"
}

# Download the exact Zig release the chosen Ghostty tag pins.
ensure_zig() {
  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64" ;;
    aarch64) arch="aarch64" ;;
    *) die "Unsupported architecture: $(uname -m)" 50 ;;
  esac

  # Zig renamed its tarballs after 0.13: zig-linux-ARCH-<ver> -> zig-ARCH-linux-<ver>.
  local url
  if [[ "$ZIG_VERSION" == 0.13.* ]]; then
    url="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-${arch}-${ZIG_VERSION}.tar.xz"
  else
    url="https://ziglang.org/download/${ZIG_VERSION}/zig-${arch}-linux-${ZIG_VERSION}.tar.xz"
  fi

  local tarball; tarball="$(basename "$url")"
  ZIG_BIN="$ZIG_ROOT/${tarball%.tar.xz}/zig"

  if [[ -x "$ZIG_BIN" ]]; then
    echo "Zig [$ZIG_VERSION] already present at [$ZIG_BIN]"
    return 0
  fi

  echo "Downloading Zig [$ZIG_VERSION] from [$url]"
  mkdir -p "$ZIG_ROOT"
  curl -fL --progress-bar -o "$ZIG_ROOT/$tarball" "$url"
  tar -xf "$ZIG_ROOT/$tarball" -C "$ZIG_ROOT"
  rm "$ZIG_ROOT/$tarball"
}

# If the chosen tag's build.zig.zon declares gtk4-layer-shell (Wayland quick
# terminal), link the distro copy when it's packaged; otherwise the build
# compiles it from source into $INSTALL_PREFIX/lib (see fix_rpath).
install_tag_deps() {
  git -C "$GHOSTTY_DIR" show "$GHOSTTY_TAG:build.zig.zon" \
    | grep -q 'gtk4-layer-shell' || return 0
  if apt-cache show libgtk4-layer-shell-dev >/dev/null 2>&1; then
    apt_install_missing libgtk4-layer-shell-dev
    LAYER_SHELL_SYSTEM=1
  fi
}

build_ghostty() {
  # -p sets up the FHS layout (desktop file, shell integration, etc.) under
  # the install prefix.
  local extra=()
  if [[ "${LAYER_SHELL_SYSTEM:-}" == 1 ]]; then
    extra+=(-fsys=gtk4-layer-shell)
  fi
  (cd "$GHOSTTY_DIR" && "$ZIG_BIN" build \
    -Doptimize=ReleaseFast \
    -p "$INSTALL_PREFIX" \
    "${extra[@]}")
}

# The bundled gtk4-layer-shell lands in $prefix/lib; point the binary at it
# instead of requiring LD_LIBRARY_PATH.
fix_rpath() {
  local bin="$INSTALL_PREFIX/bin/ghostty"
  [[ -f "$INSTALL_PREFIX/lib/libgtk4-layer-shell.so.0" ]] || return 0
  command -v patchelf >/dev/null 2>&1 || return 0
  patchelf --set-rpath '$ORIGIN/../lib' "$bin" || echo "warning: patchelf failed; Ghostty may need LD_LIBRARY_PATH=$INSTALL_PREFIX/lib"
}

install_linux() {
  require_projects
  check_headless
  install_build_deps
  select_ghostty_tag
  ensure_source
  resolve_zig_version
  ensure_zig
  install_tag_deps
  build_ghostty
  fix_rpath
}

# --- main --------------------------------------------------------------------

main() {
  case "$(uname -s)" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *) die "Unsupported platform: $(uname -s)" 60 ;;
  esac

  echo
  if command -v ghostty >/dev/null 2>&1; then
    echo "Ghostty installed successfully: $(command -v ghostty)"
    ghostty --version
  else
    echo "Ghostty installed to [$INSTALL_PREFIX] (not on PATH yet)."
  fi
}

main "$@"
