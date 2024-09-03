import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:arb_translate/src/translate_options/option_exception.dart';
import 'package:file/file.dart';

/// Enum representing the available model providers.
enum ModelProvider {
  gemini('gemini', 'Gemini'),
  vertexAi('vertex-ai', 'Vertex AI'),
  openAi('open-ai', 'Open AI');

  const ModelProvider(this.key, this.name);

  final String key;
  final String name;
}

/// Enum representing the available models.
enum Model {
  gemini10Pro('gemini-1.0-pro', 'Gemini 1.0 Pro'),
  gemini15Pro('gemini-1.5-pro', 'Gemini 1.5 Pro'),
  gemini15Flash('gemini-1.5-flash', 'Gemini 1.5 Flash'),
  gpt35Turbo('gpt-3.5-turbo', 'GPT-3.5 Turbo'),
  gpt4('gpt-4', 'GPT-4'),
  gpt4Turbo('gpt-4-turbo', 'GPT-4 Turbo'),
  gpt4O('gpt-4o', 'GPT-4o'),
  gpt4OMini('gpt-4o-mini', 'GPT-4o-mini');


  const Model(this.key, this.name);

  final String key;
  final String name;

  List<ModelProvider> get providers => geminiModels.contains(this)
      ? [ModelProvider.gemini, ModelProvider.vertexAi]
      : [ModelProvider.openAi];

  /// Returns a set of Gemini models.
  static Set<Model> get geminiModels => {
        Model.gemini10Pro,
        Model.gemini15Pro,
        Model.gemini15Flash,
      };

  /// Returns a set of GPT models.
  static Set<Model> get gptModels => {
        Model.gpt35Turbo,
        Model.gpt4,
        Model.gpt4Turbo,
        Model.gpt4O,
        Model.gpt4OMini,
      };
}

/// Class representing the options for translation.
class TranslateOptions {
  const TranslateOptions({
    required this.modelProvider,
    required this.model,
    required this.apiKey,
    required this.vertexAiProjectUrl,
    required bool? disableSafety,
    required this.context,
    required this.arbDir,
    required String? templateArbFile,
    required this.excludeLocales,
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
  final String apiKey;
  final Uri? vertexAiProjectUrl;
  final bool disableSafety;
  final String? context;
  final String arbDir;
  final String templateArbFile;
  final List<String>? excludeLocales;
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

    final modelProvider = argResults.modelProvider ??
        yamlResults.modelProvider ??
        ModelProvider.gemini;
    final model = argResults.model ??
        yamlResults.model ??
        (modelProvider == ModelProvider.openAi
            ? Model.gpt35Turbo
            : Model.gemini10Pro);

    if (!model.providers.contains(modelProvider)) {
      throw ModelProviderMismatchException();
    }

    final vertexAiProjectUrlString =
        argResults.vertexAiProjectUrl ?? yamlResults.vertexAiProjectUrl;
    final Uri? vertexAiProjectUrl = vertexAiProjectUrlString != null
        ? Uri.tryParse(vertexAiProjectUrlString)
        : null;

    if (modelProvider == ModelProvider.vertexAi) {
      if (vertexAiProjectUrlString == null) {
        throw MissingVertexAiProjectUrlException();
      }

      if (vertexAiProjectUrl == null ||
          vertexAiProjectUrl.scheme != 'https' ||
          !vertexAiProjectUrl.path.endsWith('models')) {
        throw InvalidVertexAiProjectUrlException();
      }
    }

    final context = argResults.context ?? yamlResults.context;

    if (context != null && context.length > maxContextLength) {
      throw ContextTooLongException();
    }

    return TranslateOptions(
      modelProvider: modelProvider,
      model: model,
      apiKey: apiKey,
      vertexAiProjectUrl: vertexAiProjectUrl,
      disableSafety: argResults.disableSafety ?? yamlResults.disableSafety,
      context: context,
      arbDir: argResults.arbDir ??
          yamlResults.arbDir ??
          fileSystem.path.join('lib', 'l10n'),
      templateArbFile:
          argResults.templateArbFile ?? yamlResults.templateArbFile,
      excludeLocales: argResults.excludeLocales ?? yamlResults.excludeLocales,
      useEscaping: argResults.useEscaping ?? yamlResults.useEscaping,
      relaxSyntax: argResults.relaxSyntax ?? yamlResults.relaxSyntax,
    );
  }
}
