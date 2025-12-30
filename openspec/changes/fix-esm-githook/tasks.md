# Tasks

- [x] Create `specs/esm-compatibility/spec.md` with requirements for ESM support in githook command.
- [x] Update `src/commands/githook.ts` to define `__filename` (or equivalent) using `fileURLToPath(import.meta.url)`.
- [x] Verify `oco hook set` runs without error.
