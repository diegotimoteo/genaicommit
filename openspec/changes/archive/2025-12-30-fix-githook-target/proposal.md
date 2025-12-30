# Fix Githook Symlink Target

## Why
The `githook` command currently sets the git hook to point to the current file (`__filename`), which in dev mode resolves to `src/commands/githook.ts`. This file is not the CLI entry point and lacks a shebang, causing git hook execution to fail with syntax errors (when run by `sh`).
The correct behavior is to point the hook to the CLI entry point that is currently executing (e.g. `out/cli.cjs` in prod, or `src/cli.ts` in dev context).

## What Changes
- Update `src/commands/githook.ts` to set `HOOK_URL` to `process.argv[1]`.
- This ensures the symlink points to the actual executable script being run.
- Note: In development mode (`tsx src/cli.ts`), `process.argv[1]` will be `src/cli.ts`. Since `src/cli.ts` has `#!/usr/bin/env node` shebang but contains TypeScript, git hook execution will fail unless compiled. Development testing of hooks should be done against the built artifact (`out/cli.cjs`) or requires a shebang wrapper. However, this change restores the correct production behavior and architectural intent.
