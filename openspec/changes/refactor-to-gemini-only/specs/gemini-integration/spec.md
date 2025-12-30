# Gemini Integration

## MODIFIED Requirements

### Requirement: Use Latest Gemini SDK
- The project MUST use `@google/generative-ai` version `^0.24.1`.
- The `GeminiEngine` MUST be updated to accommodate any breaking changes in the new SDK.

#### Scenario: Generate Commit Message
- Given a diff, the engine calls `model.generateContent` with the appropriate prompt.
- The response is parsed correctly as a commit message.

### Requirement: Support New Gemini Models
- The project MUST support at least:
  - `gemini-2.0-flash-001`
  - `gemini-2.0-flash-live-preview-04-09`
  - `gemini-2.5-pro`
  - `gemini-2.5-flash`
  - `gemini-3-pro`
  - `gemini-3-flash`

#### Scenario: Select Gemini 2.0
- When `OCO_MODEL=gemini-2.0-flash-001` is set, the engine uses this model for generation.
