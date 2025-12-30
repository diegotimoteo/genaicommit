import {
  GoogleGenerativeAI,
  HarmCategory,
  HarmBlockThreshold
} from '@google/generative-ai';
import axios from 'axios';
import { removeContentTags } from '../utils/removeContentTags';
import { AiEngine, AiEngineConfig, Message } from './Engine';

interface GeminiConfig extends AiEngineConfig { }

export class GeminiEngine implements AiEngine {
  config: GeminiConfig;
  client: GoogleGenerativeAI;

  constructor(config: GeminiConfig) {
    this.client = new GoogleGenerativeAI(config.apiKey);
    this.config = config;
  }

  async generateCommitMessage(
    messages: Array<Message>
  ): Promise<string | undefined> {
    const systemInstruction = messages
      .filter((m) => m.role === 'system')
      .map((m) => m.content)
      .join('\n');

    const contents = messages
      .filter((m) => m.role !== 'system')
      .map((m) => ({
        role: m.role === 'user' ? 'user' : 'model',
        parts: [{ text: m.content }]
      }));

    try {
      const model = this.client.getGenerativeModel({
        model: this.config.model,
        systemInstruction: systemInstruction ? systemInstruction : undefined
      });

      const result = await model.generateContent({
        contents,
        generationConfig: {
          maxOutputTokens: this.config.maxTokensOutput,
          temperature: 0,
          topP: 0.1
        },
        safetySettings: [
          {
            category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE
          },
          {
            category: HarmCategory.HARM_CATEGORY_HARASSMENT,
            threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE
          },
          {
            category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
            threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE
          },
          {
            category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
            threshold: HarmBlockThreshold.BLOCK_LOW_AND_ABOVE
          }
        ]
      });

      const response = await result.response;
      const content = response.text();

      if (!content) return undefined;
      return removeContentTags(content, 'think');
    } catch (error) {
      const err = error as Error;
      if (
        axios.isAxiosError<{ error?: { message: string } }>(error) &&
        error.response?.status === 401
      ) {
        const geminiError = error.response.data.error;
        if (geminiError) throw new Error(geminiError?.message);
      }

      throw err;
    }
  }
}
