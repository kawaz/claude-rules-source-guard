# Changelog

## 0.1.1 (2026-05-14)

- fix: hook が `~/.claude/rules` をハードコード参照していたのを `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/rules` に変更。kawaz の personal/emeradaco 分離環境 (~/.claude-personal, ~/.claude-emeradaco) で正しくブロックされるように

## 0.1.0 (2026-05-14)

初版。

- `PreToolUse(Write|Edit)` フックで `~/.claude/rules/` 配下への直接 Write/Edit をブロック
- block 時に `readlink -f` で symlink を解決した実体パスを stderr で案内
- ルール変更は claude-rules 系リポ (kawaz/claude-rules, kawaz/claude-rules-{zunsystem,syun}, kawaz123/claude-rules-emeradaco) 側で作業する誘導
