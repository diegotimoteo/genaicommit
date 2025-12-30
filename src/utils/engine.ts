import { getConfig } from '../commands/config';
import { AiEngine } from '../engine/Engine';
import { GeminiEngine } from '../engine/gemini';

export function getEngine(): AiEngine {
  const config = getConfig();

  const DEFAULT_CONFIG = {
    model: config.OCO_MODEL!,
    maxTokensOutput: config.OCO_TOKENS_MAX_OUTPUT!,
    maxTokensInput: config.OCO_TOKENS_MAX_INPUT!,
    baseURL: config.OCO_API_URL!,
    apiKey: config.OCO_API_KEY!
  };

  return new GeminiEngine(DEFAULT_CONFIG);
}
