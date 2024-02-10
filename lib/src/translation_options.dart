import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:file/file.dart';

class MissingGeminiApiKeyException implements Exception {
  String get message =>
      'Missing Gemini API key. Provide the key using gemini-api-key argument '
      'in command line or l10n.yaml file or using GEMINI_API_KEY environment '
      'variable';
}

class TranslationOptions {
  const TranslationOptions({
    required this.arbDir,
    String? templateArbFile,
    required this.geminiApiKey,
    bool? useEscaping,
    bool? relaxSyntax,
  })  : templateArbFile = templateArbFile ?? 'app_en.arb',
        useEscaping = useEscaping ?? false,
        relaxSyntax = relaxSyntax ?? false;

  static const arbDirKey = 'arb-dir';
  static const templateArbFileKey = 'template-arb-file';
  static const geminiApiKeyKey = 'gemini-api-key';
  static const useEscapingKey = 'use-escaping';
  static const relaxSyntaxKey = 'relax-syntax';

  final String arbDir;
  final String templateArbFile;
  final String geminiApiKey;
  final bool useEscaping;
  final bool relaxSyntax;

  factory TranslationOptions.resolve(
    FileSystem fileSystem,
    TranslateYamlResults yamlResults,
    TranslateArgResults argResults,
  ) {
    final geminiApiKey = yamlResults.geminiApiKey ??
        argResults.geminiApiKey ??
        Platform.environment['GEMINI_API_KEY'];

    if (geminiApiKey == null) {
      throw MissingGeminiApiKeyException();
    }

    return TranslationOptions(
      arbDir: yamlResults.arbDir ??
          argResults.arbDir ??
          fileSystem.path.join('lib', 'l10n'),
      templateArbFile:
          yamlResults.templateArbFile ?? argResults.templateArbFile,
      geminiApiKey: geminiApiKey,
      useEscaping: yamlResults.useEscaping ?? argResults.useEscaping,
      relaxSyntax: yamlResults.relaxSyntax ?? argResults.relaxSyntax,
    );
  }
}
