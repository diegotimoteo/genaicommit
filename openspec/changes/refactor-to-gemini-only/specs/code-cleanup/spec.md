# Code Cleanup

## MODIFIED Requirements

### Requirement: Clean Architecture
- Unused `src/engine/*.ts` files MUST be deleted.
- Unused dependencies in `package.json` MUST be removed.
- Tests related to other providers MUST be removed.

#### Scenario: Build Size
- The build should be lighter due to removed dependencies.
