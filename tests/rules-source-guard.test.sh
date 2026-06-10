#!/usr/bin/env bash
# claude-rules-source-guard の rules-source-guard.sh をドライランで検証。
# JSON で食わせ、exit code を確認する (block / pass / edge / fail-open)。
#
# CLAUDE_CONFIG_DIR を一時ディレクトリに固定してテストを hermetic にする。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/rules-source-guard.sh"
export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"

[ -x "$HOOK" ] || { echo "FAIL: $HOOK not found or not executable" >&2; exit 1; }

# rules/ 配下を判定対象にするため、一時 config dir を用意する。
TMP_CONFIG=$(mktemp -d)
trap 'rm -rf "$TMP_CONFIG"' EXIT
export CLAUDE_CONFIG_DIR="$TMP_CONFIG"
RULES_DIR="$TMP_CONFIG/rules"
mkdir -p "$RULES_DIR"
: > "$RULES_DIR/example.md"

fail=0

# usage: assert_case <label> <expected_exit> <json_input>
assert_case() {
  local label="$1"; shift
  local expected="$1"; shift
  local input="$1"; shift
  local actual
  actual=$(printf '%s' "$input" | "$HOOK" >/dev/null 2>&1; echo $?)
  actual=$(echo "$actual" | tail -1)
  if [ "$actual" = "$expected" ]; then
    printf 'PASS  %-55s (exit=%s)\n' "$label" "$actual"
  else
    printf 'FAIL  %-55s expected=%s actual=%s\n' "$label" "$expected" "$actual" >&2
    fail=$((fail+1))
  fi
}

IN="$RULES_DIR/example.md"        # rules/ 配下 (block 対象)
OUT="/tmp/not-rules-$$.md"        # rules/ 配下でない (pass)

# ---- block (exit=2): rules/ 配下への各ツール ----
assert_case "Write under rules/"   2 "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$IN\"}}"
assert_case "Edit under rules/"     2 "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$IN\",\"old_string\":\"a\",\"new_string\":\"b\"}}"
assert_case "MultiEdit under rules/" 2 "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$IN\",\"edits\":[{\"old_string\":\"a\",\"new_string\":\"b\"},{\"old_string\":\"c\",\"new_string\":\"d\"}]}}"

# ---- pass (exit=0): rules/ 配下でないパス ----
assert_case "Write outside rules/"   0 "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$OUT\"}}"
assert_case "Edit outside rules/"     0 "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$OUT\",\"old_string\":\"a\",\"new_string\":\"b\"}}"
assert_case "MultiEdit outside rules/" 0 "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$OUT\",\"edits\":[{\"old_string\":\"a\",\"new_string\":\"b\"}]}}"

# ---- edge ----
# 相対パスは判定不能 → pass
assert_case "relative path (pass)"   0 '{"tool_input":{"file_path":"rules/example.md"}}'
# rules を prefix に含むが別ディレクトリ → pass (rules/ 直下でない)
assert_case "rules-prefix sibling dir (pass)" 0 "{\"tool_input\":{\"file_path\":\"$TMP_CONFIG/rules-backup/x.md\"}}"

# ---- fail-open (exit=0): 入力不備でユーザ作業を巻き込まない ----
assert_case "empty stdin"            0 ''
assert_case "no file_path"           0 '{"tool_input":{}}'
assert_case "malformed json"         0 '{not-json'

if [ "$fail" -gt 0 ]; then
  echo "" >&2
  echo "FAILED: $fail case(s)" >&2
  exit 1
fi

echo ""
echo "All cases passed."
