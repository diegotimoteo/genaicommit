# Configuration

## ADDED Requirements

### Requirement: Simplified Provider Config
- `OCO_AI_PROVIDER` SHALL ONLY accept `gemini`.
- Helper functions related to other providers MUST be removed.

#### Scenario: Default Config
- By default, `OCO_AI_PROVIDER` MUST be `gemini` (previously `openai`).
- `OCO_MODEL` MUST default to `gemini-2.0-flash-001`.
