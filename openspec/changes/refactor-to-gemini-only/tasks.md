# Implementation Plan

1. **Dependency Updates**
   - Update `package.json` to use `@google/generative-ai` v0.24.1.
   - Remove unused dependencies (anthropic, azure, mistral, etc.).

2. **Engine Cleanup**
   - Delete all engine files except `gemini.ts` and `Engine.ts`.
   - Update `Engine.ts` interface.
   - Refactor `utils/engine.ts`.

3. **Gemini Engine Update**
   - Update `gemini.ts` for new SDK.
   - Implement support for models: `gemini-2.0-flash-001`, `gemini-2.5-pro`, `gemini-3-pro`, etc.

4. **Configuration Simplification**
   - Update `config.ts`: remove other providers from enum and validators.
   - Set `GEMINI` as default provider.
   - Update `DEFAULT_CONFIG`.

5. **Migration & Cleanup**
   - Update migrations to remove obsolete logic.
   - Clean up `migrations/_run.ts`.

6. **Tests & Docs**
   - Update tests (`gemini.test.ts`, `config.test.ts`).
   - Remove tests for other providers.
   - Update `README.md` and `action.yml`.
