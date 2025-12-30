import { GoogleGenAI } from '@google/genai';

export interface AiEngineConfig {
  apiKey: string;
  model: string;
  maxTokensOutput: number;
  maxTokensInput: number;
  baseURL?: string;
  customHeaders?: Record<string, string>;
}

export type Client = GoogleGenAI;

export interface Message {
  role: 'user' | 'system' | 'assistant';
  content: string;
}

export interface AiEngine {
  config: AiEngineConfig;
  client: Client;
  generateCommitMessage(
    messages: Array<Message>
  ): Promise<string | null | undefined>;
}
