# Githook Target Resolution

## ADDED Requirements

### Requirement: Correct Executable Linking
- The `githook` command MUST symlink the `prepare-commit-msg` hook to the CLI entry point script (`process.argv[1]`).
- It MUST NOT link to the internal module file (`__filename`).

#### Scenario: Production Hook Set
- When installed globally and running `oco hook set`, the symlink MUST point to the global `cli.cjs` (or equivalent) executable.
- Git hooks executed subsequently MUST successfully invoke the CLI.
