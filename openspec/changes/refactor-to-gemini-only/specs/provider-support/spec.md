# Provider Support

## REMOVED Requirements

### Requirement: Multiple Provider Support
- Support for OpenAI, Anthropic, Azure, Ollama, Groq, Mistral, MLX, Deepseek, AIMLAPI, OpenRouter, Flowise, TestAI is REMOVED.
- The CLI MUST NOT accept these providers in configuration.

#### Scenario: Legacy Config
- If a user has `OCO_AI_PROVIDER=openai`, the CLI should error or warn and default to Gemini.
- Logic for other providers is completely removed from codebase.
