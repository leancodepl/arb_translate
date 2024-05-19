import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:arb_translate/src/translate_options/option_exception.dart';
import 'package:file/file.dart';

/// Enum representing the available model providers.
enum ModelProvider {
  gemini('gemini'),
  vertexAi('vertex-ai'),
  openAi('open-ai');

  const ModelProvider(this.key);

  final String key;
}

/// Class representing the options for translation.
class TranslateOptions {
  const TranslateOptions({
    required this.modelProvider,
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

    if (apiKey == null) {
      throw MissingApiKeyException();
    }

    final modelProvider = argResults.modelProvider ??
        yamlResults.modelProvider ??
        ModelProvider.gemini;

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
