# Design

## Simplified Architecture
The system will be single-provider.
- `src/engine/gemini.ts` will be the sole implementation of `Engine`.
- Configuration will strictly validate for `OCO_AI_PROVIDER=gemini`.

## Diagrams
```mermaid
graph TD
    A[CLI] --> B[Commands]
    B --> H[GeminiEngine]
    H --> I[@google/generative-ai v0.24.1]
```
