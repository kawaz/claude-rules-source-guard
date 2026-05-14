# Changelog

## 0.1.0 (2026-05-14)

初版。

- `PreToolUse(Write|Edit)` フックで `~/.claude/rules/` 配下への直接 Write/Edit をブロック
- block 時に `readlink -f` で symlink を解決した実体パスを stderr で案内
- ルール変更は claude-rules 系リポ (kawaz/claude-rules, kawaz/claude-rules-{zunsystem,syun}, kawaz123/claude-rules-emeradaco) 側で作業する誘導
