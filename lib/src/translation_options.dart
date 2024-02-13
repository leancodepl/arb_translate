import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:file/file.dart';

class MissingApiKeyException implements Exception {
  String get message =>
      'Missing API key. Provide the key using api-key argument in command line '
      'or using arb-translate-api-key property in l10n.yaml file or using '
      'ARB_TRANSLATE_API_KEY environment variable';
}

class MissingVertexAiProjectUrlException implements Exception {
  String get message =>
      'Using Vertex AI model provider requires a project URL. Provide the URL '
      'using vertex-ai-project-url argument in command line or using '
      'arb-translate-vertex-ai-project-url property in l10n.yaml file';
}

class InvalidVertexAiProjectUrlException implements Exception {
  String get message =>
      'Invalid Vertex AI project URL. The URL should be a valid HTTPS URL and '
      'should end with "models" eg. "https://{api-endpoint}/v1/projects/'
      '{project-id}/locations/{location-id}/publishers/google/models"';
}

enum ModelProvider {
  gemini('gemini'),
  vertexAi('vertex-ai');

  const ModelProvider(this.key);

  final String key;
}

class TranslationOptions {
  const TranslationOptions({
    required this.modelProvider,
    required this.apiKey,
    required this.vertexAiProjectUrl,
    required this.arbDir,
    required String? templateArbFile,
    required bool? useEscaping,
    required bool? relaxSyntax,
  })  : templateArbFile = templateArbFile ?? 'app_en.arb',
        useEscaping = useEscaping ?? false,
        relaxSyntax = relaxSyntax ?? false;

  static const arbDirKey = 'arb-dir';
  static const templateArbFileKey = 'template-arb-file';
  static const useEscapingKey = 'use-escaping';
  static const relaxSyntaxKey = 'relax-syntax';

  final ModelProvider modelProvider;
  final String apiKey;
  final Uri? vertexAiProjectUrl;
  final String arbDir;
  final String templateArbFile;
  final bool useEscaping;
  final bool relaxSyntax;

  factory TranslationOptions.resolve(
    FileSystem fileSystem,
    TranslateYamlResults yamlResults,
    TranslateArgResults argResults,
  ) {
    final apiKey = yamlResults.apiKey ??
        argResults.apiKey ??
        Platform.environment['ARB_TRANSLATE_API_KEY'];

    if (apiKey == null) {
      throw MissingApiKeyException();
    }

    final modelProvider = yamlResults.modelProvider ??
        argResults.modelProvider ??
        ModelProvider.gemini;

    final vertexAiProjectUrlString =
        yamlResults.vertexAiProjectUrl ?? argResults.vertexAiProjectUrl;
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

    return TranslationOptions(
      modelProvider: modelProvider,
      apiKey: apiKey,
      vertexAiProjectUrl: vertexAiProjectUrl,
      arbDir: yamlResults.arbDir ??
          argResults.arbDir ??
          fileSystem.path.join('lib', 'l10n'),
      templateArbFile:
          yamlResults.templateArbFile ?? argResults.templateArbFile,
      useEscaping: yamlResults.useEscaping ?? argResults.useEscaping,
      relaxSyntax: yamlResults.relaxSyntax ?? argResults.relaxSyntax,
    );
  }
}
