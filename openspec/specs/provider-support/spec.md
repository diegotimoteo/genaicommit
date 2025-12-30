# provider-support Specification

## Purpose
TBD - created by archiving change refactor-to-gemini-only. Update Purpose after archive.
## Requirements
### Requirement: Multiple Provider Support
- Support for OpenAI, Anthropic, Azure, Ollama, Groq, Mistral, MLX, Deepseek, AIMLAPI, OpenRouter, Flowise, TestAI MUST be REMOVED.
- The CLI MUST NOT accept these providers in configuration.

#### Scenario: Legacy Config
- If a user has `OCO_AI_PROVIDER=openai`, the CLI should error or warn and default to Gemini.
- Logic for other providers is completely removed from codebase.

