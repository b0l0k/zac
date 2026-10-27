#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cp "$repo_root/action/package.json" "$repo_root/action/bun.lock" "$tmpdir/"

# Change one valid direct dependency version while leaving the copied lock untouched.
sed -i -E 's/"commander": "[^"]+"/"commander": "999999.0.0"/' "$tmpdir/package.json"
grep -q '"commander": "999999.0.0"' "$tmpdir/package.json"

log="$tmpdir/bun-install.log"
if bun install --cwd "$tmpdir" --frozen-lockfile --dry-run --offline >"$log" 2>&1; then
  cat "$log"
  echo "ERROR: frozen install accepted a deliberately mismatched manifest and lockfile" >&2
  exit 1
fi

cat "$log"
if ! grep -qi 'lockfile' "$log"; then
  echo "ERROR: frozen install failed without reporting a lockfile mismatch" >&2
  exit 1
fi

echo "PASS: Bun frozen install rejected the manifest/lockfile mismatch."
