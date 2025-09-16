import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:arb_translate/src/translate_options/option_exception.dart';
import 'package:file/file.dart';

/// Enum representing the available model providers.
enum ModelProvider {
  gemini('gemini', 'Gemini'),
  openAi('open-ai', 'Open AI'),
  customOpenAiCompatible(
    'custom',
    'Custom Open AI compatible',
  );

  const ModelProvider(this.key, this.name);

  final String key;
  final String name;
}

/// Enum representing the available models.
enum Model {
  gemini25Pro('gemini-2.5-pro', 'Gemini 2.5 Pro', ModelProvider.gemini),
  gemini25Flash('gemini-2.5-flash', 'Gemini 2.5 Flash', ModelProvider.gemini),
  gemini25FlashLite(
      'gemini-2.5-flash-lite', 'Gemini 2.5 Flash Lite', ModelProvider.gemini),
  gemini20Flash('gemini-2.0-flash', 'Gemini 2.0 Flash', ModelProvider.gemini),
  gemini15Flash('gemini-1.5-flash', 'Gemini 1.5 Flash', ModelProvider.gemini),
  gemini15Pro('gemini-1.5-pro', 'Gemini 1.5 Pro', ModelProvider.gemini),
  gpt35Turbo('gpt-3.5-turbo', 'GPT-3.5 Turbo', ModelProvider.openAi),
  gpt4('gpt-4', 'GPT-4', ModelProvider.openAi),
  gpt4Turbo('gpt-4-turbo', 'GPT-4 Turbo', ModelProvider.openAi),
  gpt4O('gpt-4o', 'GPT-4o', ModelProvider.openAi),
  gpt5('gpt-5', 'GPT-5', ModelProvider.openAi),
  gpt5Mini('gpt-5-mini', 'GPT-5 Mini', ModelProvider.openAi),
  gpt5Nano('gpt-5-nano', 'GPT-5 Nano', ModelProvider.openAi);

  const Model(this.key, this.name, this.provider);

  final String key;
  final String name;
  final ModelProvider provider;
}

/// Class representing the options for translation.
class TranslateOptions {
  const TranslateOptions({
    required this.modelProvider,
    required this.model,
    required this.customModel,
    required this.apiKey,
    required this.customModelProviderBaseUrl,
    required bool? disableSafety,
    required this.context,
    required this.arbDir,
    required String? templateArbFile,
    required this.excludeLocales,
    required this.batchSize,
    required bool? useEscaping,
    required bool? relaxSyntax,
  })  : disableSafety = disableSafety ?? false,
        templateArbFile = templateArbFile ?? 'app_en.arb',
        useEscaping = useEscaping ?? false,
        relaxSyntax = relaxSyntax ?? false;

  static const arbDirKey = 'arb-dir';
  static const templateArbFileKey = 'template-arb-file';
  static const useEscapingKey = 'use-escaping';
  static const relaxSyntaxKey = 'relax-syntax';

  static const maxContextLength = 32768;

  final ModelProvider modelProvider;
  final Model model;
  final String? customModel;
  final String apiKey;
  final Uri? customModelProviderBaseUrl;
  final bool disableSafety;
  final String? context;
  final String arbDir;
  final String templateArbFile;
  final List<String>? excludeLocales;
  final int batchSize;
  final bool useEscaping;
  final bool relaxSyntax;

  /// Factory method to resolve [TranslateOptions] from command line arguments
  /// and YAML configuration.
  factory TranslateOptions.resolve(
    FileSystem fileSystem,
    TranslateArgResults argResults,
    TranslateYamlResults yamlResults,
  ) {
    final apiKey = argResults.apiKey ??
        yamlResults.apiKey ??
        Platform.environment['ARB_TRANSLATE_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw MissingApiKeyException();
    }

    final customModel = argResults.customModel ?? yamlResults.customModel;
    final model = argResults.model ?? yamlResults.model ?? Model.gemini25Flash;

    final modelProvider = customModel != null
        ? ModelProvider.customOpenAiCompatible
        : model.provider;

    final customModelProviderBaseUrlString =
        argResults.customModelProviderBaseUrl ??
            yamlResults.customModelProviderBaseUrl;
    final Uri? customModelProviderBaseUrl =
        customModelProviderBaseUrlString != null
            ? Uri.tryParse(customModelProviderBaseUrlString)
            : null;

    if (modelProvider == ModelProvider.customOpenAiCompatible) {
      if (customModelProviderBaseUrlString == null) {
        throw MissingCustomModelProviderBaseUrlException();
      }

      if (customModelProviderBaseUrl == null) {
        throw InvalidCustomModelProviderBaseUrlException();
      }
    }

    final context = argResults.context ?? yamlResults.context;

    if (context != null && context.length > maxContextLength) {
      throw ContextTooLongException();
    }

    return TranslateOptions(
      modelProvider: modelProvider,
      customModelProviderBaseUrl: customModelProviderBaseUrl,
      model: model,
      customModel: customModel,
      apiKey: apiKey,
      disableSafety: argResults.disableSafety ?? yamlResults.disableSafety,
      context: context,
      arbDir: argResults.arbDir ??
          yamlResults.arbDir ??
          fileSystem.path.join('lib', 'l10n'),
      templateArbFile:
          argResults.templateArbFile ?? yamlResults.templateArbFile,
      excludeLocales: argResults.excludeLocales ?? yamlResults.excludeLocales,
      batchSize: argResults.batchSize ?? yamlResults.batchSize ?? 4096,
      useEscaping: argResults.useEscaping ?? yamlResults.useEscaping,
      relaxSyntax: argResults.relaxSyntax ?? yamlResults.relaxSyntax,
    );
  }
}
