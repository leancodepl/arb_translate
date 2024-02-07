import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

class TranslationOptions {
  const TranslationOptions({
    required this.arbDir,
    String? templateArbFile,
    required this.geminiApiKey,
  }) : templateArbFile = templateArbFile ?? 'app_en.arb';

  static const arbDirKey = 'arb-dir';
  static const templateArbFileKey = 'template-arb-file';
  static const geminiApiKeyKey = 'gemini-api-key';

  static final missingGeminiApiKeyError = Exception(
    'Missing Gemini API key. Provide the key using gemini-api-key argument '
    'in command line or l10n.yaml file or using GEMINI_API_KEY environment '
    'variable',
  );

  final String arbDir;
  final String templateArbFile;
  final String geminiApiKey;

  factory TranslationOptions.parse(
    FileSystem fileSystem,
    ArgResults argResults,
  ) {
    final defaultArbDir = fileSystem.path.join('lib', 'l10n');

    if (fileSystem.file('l10n.yaml').existsSync()) {
      print(
        'Because l10n.yaml exists, the options defined there will be used '
        'instead.\nTo use the command line arguments, delete the l10n.yaml '
        'file in the Flutter project.\n\n',
      );

      return _parseTranslationOptionsFromYAML(
        file: fileSystem.file('l10n.yaml'),
        defaultArbDir: defaultArbDir,
      );
    } else {
      return _parseTranslationOptionsFromCommand(
        argResults: argResults,
        defaultArbDir: defaultArbDir,
      );
    }
  }

  static TranslationOptions _parseTranslationOptionsFromYAML({
    required File file,
    required String defaultArbDir,
  }) {
    final contents = file.readAsStringSync();
    final apiKeyEnvVar = Platform.environment['GEMINI_API_KEY'];

    if (contents.trim().isEmpty) {
      if (apiKeyEnvVar == null) {
        throw missingGeminiApiKeyError;
      }

      return TranslationOptions(
        arbDir: defaultArbDir,
        geminiApiKey: apiKeyEnvVar,
      );
    }

    final yamlNode = loadYamlNode(file.readAsStringSync());

    if (yamlNode is! YamlMap) {
      throw Exception(
        'Expected ${file.path} to contain a map, instead was $yamlNode',
      );
    }

    final apiKey = _tryReadString(yamlNode, geminiApiKeyKey) ?? apiKeyEnvVar;

    if (apiKey == null) {
      throw missingGeminiApiKeyError;
    }

    return TranslationOptions(
      arbDir: _tryReadUri(yamlNode, arbDirKey)?.path ?? defaultArbDir,
      templateArbFile: _tryReadUri(yamlNode, templateArbFileKey)?.path,
      geminiApiKey: apiKey,
    );
  }

  static Uri? _tryReadUri(YamlMap yamlMap, String key) {
    final value = _tryReadString(yamlMap, key);

    if (value == null) {
      return null;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      throw Exception(
        'Expected "$key" to have a String value, instead was "$value"',
      );
    }

    return uri;
  }

  static String? _tryReadString(YamlMap yamlMap, String key) {
    final value = yamlMap[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw Exception(
        'Expected "$key" to have a String value, instead was "$value"',
      );
    }

    return value;
  }

  static TranslationOptions _parseTranslationOptionsFromCommand({
    required ArgResults argResults,
    required String defaultArbDir,
  }) {
    final apiKey = (argResults[geminiApiKeyKey] as String?) ??
        Platform.environment['GEMINI_API_KEY'];

    if (apiKey == null) {
      throw missingGeminiApiKeyError;
    }

    return TranslationOptions(
      arbDir: argResults[arbDirKey] ?? defaultArbDir,
      templateArbFile: argResults[templateArbFileKey],
      geminiApiKey: apiKey,
    );
  }
}
