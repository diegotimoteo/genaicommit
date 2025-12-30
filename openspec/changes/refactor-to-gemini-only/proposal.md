# Refactor to Gemini Only

## Context
The project intentionally supports multiple LLM providers, but the current state is complex and the Gemini integration is outdated (v0.11.4). We want to simplify the project to focus exclusively on Gemini and leverage its latest capabilities.

## Goals
- Update `@google/generative-ai` to v0.24.1.
- Support Gemini 2.0, 2.5, and 3.0.
- Remove all other 12 providers.
- Simplify configuration and architecture.
