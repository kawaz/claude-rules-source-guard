#!/bin/bash
# PreToolUse(Write|Edit|MultiEdit) hook: $CLAUDE_CONFIG_DIR/rules/ 配下への直接編集をブロック。
#
# Write / Edit / MultiEdit はいずれも tool_input.file_path をトップレベルに持つため
# (MultiEdit の edits[] は判定に不要)、file_path のみで判定すれば全ツールを覆える。
#
# rules/ ディレクトリは claude-rules-* 系リポからのディレクトリ symlink で
# 構成されており、直編集だとリポ管理外で変更が混入する。block して、
# リポ側で作業するよう案内する。
#
# NOTE: `set -e` は使わない。フック自体の不具合 (jq 不在、JSON 不正等) は
# 通過 (exit 0) させて、ユーザの作業を巻き込まないこと。

# CLAUDE_CONFIG_DIR が未設定なら従来の ~/.claude を見る (後方互換)
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
rules_dir="$config_dir/rules"

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$file_path" ] || exit 0

# 絶対パスでないものは判定不能、通過
case "$file_path" in
  /*) ;;
  *) exit 0 ;;
esac

# $CLAUDE_CONFIG_DIR/rules/ 配下かどうか
case "$file_path" in
  "$rules_dir"/*) ;;
  *) exit 0 ;;
esac

# 実体パス解決 (symlink 越し)
real_path=$(readlink -f "$file_path" 2>/dev/null || echo "$file_path")

cat >&2 <<EOF
BLOCK: \`${rules_dir}/\` 配下への直接編集はできません。

このディレクトリは claude-rules-* 系リポからのディレクトリ symlink で
構成されており、直編集だとリポ管理外で変更が混入します。

該当ファイルの実体パス:
  ${real_path}

ルール変更は実体のあるリポ側 (上記実体パスのリポ) で作業してください。
リポ側で編集後、jj describe + commit + \`pkf run push\` で反映されます。
ディレクトリ symlink 構成なので setup.sh の再実行は不要です。
EOF
exit 2
