# Project Context

## Purpose
OpenCommit is a CLI tool and GitHub Action that auto-generates meaningful, descriptive git commit messages using AI (OpenAI, Ollama, Anthropic, etc.). It aims to improve commit history quality by replacing generic messages with insightful descriptions of changes.

## Tech Stack
- **Languages**: TypeScript, JavaScript (Node.js)
- **Runtime**: Node.js (ES Modules)
- **CLI Framework**: `cleye` (Argument parsing), `@clack/prompts` / `inquirer` (Interactivity)
- **AI Integration**: `openai`, `@anthropic-ai/sdk`, `@google/generative-ai`, `@mistralai/mistralai`, etc.
- **Build Tool**: `esbuild`
- **Testing**: `jest`, `ts-jest`
- **Linting/Formatting**: `eslint`, `prettier`

## Project Conventions

### Code Style
- **Formatting**: Prettier is enforced (`.prettierrc`).
- **Linting**: ESLint with `@typescript-eslint/recommended` and `simple-import-sort` requires organized imports.
- **Modules**: Uses ES Modules (`"type": "module"` in `package.json`) and `NodeNext` module resolution.
- **Strictness**: strict mode enabled in `tsconfig.json`.

### Architecture Patterns
- **CLI Entry**: `src/cli.ts` (dev) -> `out/cli.cjs` (prod).
- **Configuration**: Uses `ini` format for local/global config (`.opencommit` or `.env`).
- **Git Hooks**: Can serve as a `prepare-commit-msg` hook.

### Testing Strategy
- **Framework**: Jest.
- **Types**:
    - **Unit Tests**: `test/unit`
    - **E2E Tests**: `test/e2e` (running inside Docker via `oco-test` image)
- **CI**: GitHub Actions workflow.

### Git Workflow
- **Branching**: `master` is the main release branch.
- **Commits**: Ideally compliant with Conventional Commits (or whatever the tool itself generates!).
- **Release**: Semantic versioning.

## Domain Context
- **AI Models**: Supports multiple providers (OpenAI, Azure, Ollama, etc.) and models (GPT-4, etc.) to generate text.
- **Git Operations**: Heavily interacts with `git` commands (diff, add, commit) via child processes.

## Important Constraints
- **Performance**: CLI should be fast (hence `esbuild`).
- **Compatibility**: Must handle various git environments and configuration states.
- **Token Limits**: Must respect context window limits of different AI models (`OCO_TOKENS_MAX_INPUT`).

## External Dependencies
- **LLM APIs**: OpenAI, Anthropic, Gemini, DeepSeek, etc.
- **Git**: Requires git installed on the user's system.
