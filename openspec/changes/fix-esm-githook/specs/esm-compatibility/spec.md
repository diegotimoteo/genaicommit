# ESM Compatibility

## ADDED Requirements

### Requirement: ESM-Compatible Path Resolution
- The `githook` command MUST NOT use `__filename` or `__dirname` directly as they are undefined in ESM.
- The command MUST use `import.meta.url` derived paths to locate the current script file.

#### Scenario: Running Hook Set
- When a user runs `npm run dev hook set`, the command should execute without `ReferenceError`.
- It should correctly identify the script path to symlink or reference in the git hook.
