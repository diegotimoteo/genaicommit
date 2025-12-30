import { GoogleGenerativeAI } from '@google/generative-ai';

export interface AiEngineConfig {
  apiKey: string;
  model: string;
  maxTokensOutput: number;
  maxTokensInput: number;
  baseURL?: string;
  customHeaders?: Record<string, string>;
}

export type Client = GoogleGenerativeAI;

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
