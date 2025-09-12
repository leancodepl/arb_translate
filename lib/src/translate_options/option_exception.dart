import 'package:arb_translate/src/translate_options/translate_options.dart';

sealed class OptionException implements Exception {
  String get message;
}

/// Exception thrown when an API key is missing.
class MissingApiKeyException implements OptionException {
  @override
  String get message =>
      'Missing API key. Provide the key using api-key argument in command line '
      'or using arb-translate-api-key property in l10n.yaml file or using '
      'ARB_TRANSLATE_API_KEY environment variable';
}

/// Exception thrown when the selected model doesn't match the selected model
/// provider.
class ModelProviderMismatchException implements OptionException {
  @override
  String get message =>
      'Selected model does not match selected model provider. Select different '
      'model or different model provider';
}

/// Exception thrown when a custom model is missing.
class MissingCustomModelException implements OptionException {
  @override
  String get message =>
      'Using custom OpenAI compatible model provider requires a custom model. '
      'Provide the model using custom-model argument in command line or using '
      'arb-translate-custom-model property in l10n.yaml file';
}

/// Exception thrown when a custom model provider base URL is missing.
class MissingCustomModelProviderBaseUrlException implements OptionException {
  @override
  String get message =>
      'Using custom OpenAI compatible model provider requires a base URL. '
      'Provide the URL using custom-model-provider-base-url argument in '
      'command line or using arb-translate-custom-model-provider-base-url '
      'property in l10n.yaml file';
}

/// Exception thrown when an invalid custom model provider base URL is provided.
class InvalidCustomModelProviderBaseUrlException implements OptionException {
  @override
  String get message => 'Invalid custom model provider base URL.';
}

/// Exception thrown when the translation context is too long.
class ContextTooLongException implements OptionException {
  @override
  String get message =>
      'Context is too long. The maximum length of translation context is '
      '${TranslateOptions.maxContextLength} characters';
}
