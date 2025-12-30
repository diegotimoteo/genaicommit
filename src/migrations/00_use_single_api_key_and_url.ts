import {
  CONFIG_KEYS,
  getConfig,
  OCO_AI_PROVIDER_ENUM,
  setConfig
} from '../commands/config';

export default function () {
  const config = getConfig({ setDefaultValues: false }) as any;

  const aiProvider = config.OCO_AI_PROVIDER;

  let apiKey: string | undefined;
  let apiUrl: string | undefined;

  if (aiProvider === OCO_AI_PROVIDER_ENUM.GEMINI) {
    apiKey = config['OCO_GEMINI_API_KEY'];
    apiUrl = config['OCO_GEMINI_BASE_PATH'];
  } else {
    throw new Error(
      `Migration failed, set AI provider first. Run "oco config set OCO_AI_PROVIDER=<provider>", where <provider> is one of: ${Object.values(
        OCO_AI_PROVIDER_ENUM
      ).join(', ')}`
    );
  }

  if (apiKey) setConfig([[CONFIG_KEYS.OCO_API_KEY, apiKey]]);

  if (apiUrl) setConfig([[CONFIG_KEYS.OCO_API_URL, apiUrl]]);
}
