# Fix ESM Githook Error

## Why
The project uses ES Modules (`"type": "module"` in `package.json`), but `src/commands/githook.ts` indiscriminately uses `__filename`, which is not defined in ESM contexts. This causes the `oco hook set` command to crash with a `ReferenceError`.

## What Changes
- Update `src/commands/githook.ts` to derive the filename using `import.meta.url` and `fileURLToPath` (standard ESM approach).
- Ensure cross-platform compatibility where possible (though git hooks are shell scripts, the node script generation should use correct paths).
