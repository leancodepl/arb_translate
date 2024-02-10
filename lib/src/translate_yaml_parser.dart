import 'package:arb_translate/arb_translate.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

class TranslateYamlResults {
  const TranslateYamlResults({
    required this.geminiApiKey,
    required this.arbDir,
    required this.templateArbFile,
    required this.useEscaping,
    required this.relaxSyntax,
  });

  const TranslateYamlResults.empty()
      : geminiApiKey = null,
        arbDir = null,
        templateArbFile = null,
        useEscaping = null,
        relaxSyntax = null;

  final String? geminiApiKey;
  final String? arbDir;
  final String? templateArbFile;
  final bool? useEscaping;
  final bool? relaxSyntax;
}

class TranslateYamlParser {
  TranslateYamlResults parse(File file) {
    if (!file.existsSync()) {
      return TranslateYamlResults.empty();
    }

    final contents = file.readAsStringSync();

    if (contents.trim().isEmpty) {
      return TranslateYamlResults.empty();
    }

    final yamlNode = loadYamlNode(file.readAsStringSync());

    if (yamlNode is! YamlMap) {
      throw FormatException(
        'Expected ${file.path} to contain a map, instead was $yamlNode',
      );
    }

    return TranslateYamlResults(
      arbDir: _tryReadUri(yamlNode, TranslationOptions.arbDirKey)?.path,
      templateArbFile:
          _tryReadUri(yamlNode, TranslationOptions.templateArbFileKey)?.path,
      geminiApiKey:
          _tryReadString(yamlNode, TranslationOptions.geminiApiKeyKey),
      useEscaping: _tryReadBool(yamlNode, TranslationOptions.useEscapingKey),
      relaxSyntax: _tryReadBool(yamlNode, TranslationOptions.relaxSyntaxKey),
    );
  }

  static bool? _tryReadBool(YamlMap yamlMap, String key) {
    final Object? value = yamlMap[key];
    if (value == null) {
      return null;
    }
    if (value is! bool) {
      throw FormatException(
        'Expected "$key" to have a bool value, instead was "$value"',
      );
    }
    return value;
  }

  static Uri? _tryReadUri(YamlMap yamlMap, String key) {
    final value = _tryReadString(yamlMap, key);

    if (value == null) {
      return null;
    }

    final uri = Uri.tryParse(value);

    if (uri == null) {
      throw FormatException(
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
      throw FormatException(
        'Expected "$key" to have a String value, instead was "$value"',
      );
    }

    return value;
  }
}
