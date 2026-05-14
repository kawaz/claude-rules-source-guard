# claude-rules-source-guard

Claude Code plugin: `PreToolUse(Write|Edit)` hook that blocks direct edits
under `~/.claude/rules/` and routes changes through the source-of-truth
[claude-rules](https://github.com/kawaz/claude-rules) repo.

## Why

`~/.claude/rules/` is configured as directory symlinks pointing at multiple
`claude-rules{,-emeradaco,-zunsystem,-syun}` repos. Editing files via the
symlink path looks fine at first glance, but actually rewrites repo content
without going through the repo's commit/push flow. Easy to lose changes.

This hook blocks such edits at the tool layer (exit 2) and reports the
resolved repo path so the model knows where to actually go.

## Install

```
/plugin marketplace add kawaz/claude-rules-source-guard
/plugin install claude-rules-source-guard@claude-rules-source-guard
```

## Behavior

- Triggers on `Write` / `Edit` whose `file_path` is under `$HOME/.claude/rules/`.
- Resolves the symlink target with `readlink -f` and includes it in the block message.
- Pass-through (exit 0) for all other paths and for relative paths.

## Related

- [kawaz/claude-rules](https://github.com/kawaz/claude-rules) — the SSoT repo this guard protects
- [kawaz/claude-push-guard](https://github.com/kawaz/claude-push-guard) — sibling plugin (same pattern)
