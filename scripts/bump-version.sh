#!/usr/bin/env bash
# Usage: scripts/bump-version.sh 0.1.1
# Sets "version" in every plugin manifest.
set -euo pipefail
v="${1:?usage: bump-version.sh X.Y.Z}"
for f in .claude-plugin/plugin.json .codex-plugin/plugin.json .grok-plugin/plugin.json .cursor-plugin/plugin.json; do
  sed -i -E "s/(\"version\"[[:space:]]*:[[:space:]]*\")[^\"]*\"/\1$v\"/" "$f"
  echo "$f -> $v"
done
