const mockGenerateContent = jest.fn();
const mockGoogleGenAIInstance = {
  models: {
    generateContent: mockGenerateContent
  }
};
const MockGoogleGenAI = jest.fn(() => mockGoogleGenAIInstance);

jest.mock('@google/genai', () => ({
  GoogleGenAI: MockGoogleGenAI,
  HarmCategory: {
    HARM_CATEGORY_DANGEROUS_CONTENT: 'HARM_CATEGORY_DANGEROUS_CONTENT',
    HARM_CATEGORY_HARASSMENT: 'HARM_CATEGORY_HARASSMENT',
    HARM_CATEGORY_HATE_SPEECH: 'HARM_CATEGORY_HATE_SPEECH',
    HARM_CATEGORY_SEXUALLY_EXPLICIT: 'HARM_CATEGORY_SEXUALLY_EXPLICIT'
  },
  HarmBlockThreshold: {
    BLOCK_LOW_AND_ABOVE: 'BLOCK_LOW_AND_ABOVE'
  }
}));

import { GeminiEngine } from '../../src/engine/gemini';
import {
  ConfigType,
  getConfig,
  OCO_AI_PROVIDER_ENUM
} from '../../src/commands/config';
import { Message } from '../../src/engine/Engine';

describe('Gemini', () => {
  let gemini: GeminiEngine;
  let mockConfig: ConfigType;
  let mockExit: jest.SpyInstance;

  const mockGemini = () => {
    mockConfig = getConfig() as ConfigType;

    gemini = new GeminiEngine({
      apiKey: mockConfig.OCO_API_KEY || '',
      model: mockConfig.OCO_MODEL,
      maxTokensInput: mockConfig.OCO_TOKENS_MAX_INPUT,
      maxTokensOutput: mockConfig.OCO_TOKENS_MAX_OUTPUT
    });
  };

  const oldEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...oldEnv };

    mockGenerateContent.mockReset();
    MockGoogleGenAI.mockClear();

    jest.mock('../src/commands/config');

    jest.mock('@clack/prompts', () => ({
      intro: jest.fn(),
      outro: jest.fn()
    }));

    mockExit = jest.spyOn(process, 'exit').mockImplementation(() => { throw new Error('exit'); });

    mockConfig = getConfig() as ConfigType;

    mockConfig.OCO_AI_PROVIDER = OCO_AI_PROVIDER_ENUM.GEMINI;
    mockConfig.OCO_API_KEY = 'mock-api-key';
    mockConfig.OCO_MODEL = 'gemini-1.5-flash';
  });

  afterEach(() => {
    gemini = undefined as any;
    jest.clearAllMocks();
  });

  afterAll(() => {
    mockExit.mockRestore();
    process.env = oldEnv;
  });

  it.skip('should exit process if OCO_API_KEY is not set and command is not config', () => {
    process.env.OCO_API_KEY = undefined;
    process.env.OCO_AI_PROVIDER = 'gemini';

    mockGemini();

    expect(mockExit).toHaveBeenCalledWith(1);
  });

  it('should generate commit message', async () => {
    mockGenerateContent.mockResolvedValue({
      text: 'generated content'
    });

    mockGemini();

    const messages: Array<Message> =
      [
        { role: 'system', content: 'system message' },
        { role: 'assistant', content: 'assistant message' }
      ];

    // Spy on the method of the instance we created
    // But since generateCommitMessage calls client.models.generateContent, we verify that.

    // Using the real implementation of generateCommitMessage to verify it calls the mock client
    const result = await gemini.generateCommitMessage(messages);

    expect(result).toEqual('generated content');
    expect(mockGenerateContent).toHaveBeenCalled();
  });
});
