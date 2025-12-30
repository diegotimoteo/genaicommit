import { jest } from '@jest/globals';
import type { ConfigType } from '../../src/commands/config';
import type { Message } from '../../src/engine/Engine';

const mockGenerateContent = jest.fn();
const mockGenerativeModel = {
  generateContent: mockGenerateContent
};
const mockGoogleGenAIInstance = {
  getGenerativeModel: jest.fn(() => mockGenerativeModel)
};
const MockGoogleGenerativeAI = jest.fn(() => mockGoogleGenAIInstance);

// Mocking before imports
jest.unstable_mockModule('@google/generative-ai', () => ({
  GoogleGenerativeAI: MockGoogleGenerativeAI,
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

jest.unstable_mockModule('../src/commands/config', () => ({
  getConfig: jest.fn(),
  OCO_AI_PROVIDER_ENUM: { GEMINI: 'gemini' }
}));

jest.unstable_mockModule('@clack/prompts', () => ({
  intro: jest.fn(),
  outro: jest.fn()
}));

// Dynamic imports
const { GeminiEngine } = await import('../../src/engine/gemini');
const { getConfig, OCO_AI_PROVIDER_ENUM } = await import(
  '../../src/commands/config'
);

describe('Gemini', () => {
  let gemini: any;
  let mockConfig: ConfigType;
  let mockExit: any;

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
    MockGoogleGenerativeAI.mockClear();

    (getConfig as jest.Mock).mockReturnValue({
      OCO_AI_PROVIDER: OCO_AI_PROVIDER_ENUM.GEMINI,
      OCO_API_KEY: 'mock-api-key',
      OCO_MODEL: 'gemini-1.5-flash',
      OCO_TOKENS_MAX_INPUT: 1000,
      OCO_TOKENS_MAX_OUTPUT: 100
    });

    mockExit = jest
      .spyOn(process, 'exit')
      .mockImplementation((() => {
        throw new Error('exit');
      }) as any);
  });

  afterEach(() => {
    gemini = undefined;
    jest.clearAllMocks();
  });

  afterAll(() => {
    mockExit.mockRestore();
    process.env = oldEnv;
  });

  it.skip('should exit process if OCO_API_KEY is not set and command is not config', () => {
    process.env.OCO_API_KEY = undefined;
    process.env.OCO_AI_PROVIDER = 'gemini';

    (getConfig as jest.Mock).mockReturnValue({
      ...getConfig(),
      OCO_API_KEY: undefined
    });

    mockGemini();

    expect(mockExit).toHaveBeenCalledWith(1);
  });

  it('should generate commit message', async () => {
    mockGenerateContent.mockResolvedValue({
      response: Promise.resolve({
        text: () => 'generated content'
      })
    });

    mockGemini();

    const messages: Array<Message> = [
      { role: 'system', content: 'system message' },
      { role: 'assistant', content: 'assistant message' }
    ];

    const result = await gemini.generateCommitMessage(messages);

    expect(result).toEqual('generated content');
    expect(mockGenerateContent).toHaveBeenCalled();
  });
});

