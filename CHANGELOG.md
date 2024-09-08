## 1.1.0
- Add custom model support

## 1.0.0
- Add ChatGPT support
- Add model selection option

## 0.1.4
- Improve reliability by trimming model response
- Specify JSON output in prompt
- Add dart docs for public API

## 0.1.3
- Add option to disable safety settings
- Add option to exclude locales
- Fix quota exceeded error handling for Vertex AI
- Fix setting use escaping and relax syntax in `l10n.yaml`
- Update `google_generative_ai` dependency

## 0.1.2
- Fix setting model provider in `l10n.yaml`

## 0.1.1
- Fix citation parsing issue
  ([#1](https://github.com/leancodepl/arb_translate/issues/1))
- Update `google_generative_ai` dependency

## 0.1.0
- Fix configuration type precedence. Command arguments > l10n.yaml properties >
  Environment variables
- Catch invalid Vertex AI token exception

## 0.0.3
- Update `google_generative_ai` dependency
- Remove workaround for http client override issue in `google_generative_ai`
  ([#64](https://github.com/google/generative-ai-dart/issues/64))
- Add more information to Gemini API not available in user region error message
- Update README.md

## 0.0.2
- Fix img tag in README.md
- Update dependencies

## 0.0.1

- Initial version
