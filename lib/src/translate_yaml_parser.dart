import 'package:arb_translate/arb_translate.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

class TranslateYamlResults {
  const TranslateYamlResults({
    required this.modelProvider,
    required this.apiKey,
    required this.vertexAiProjectUrl,
    required this.arbDir,
    required this.templateArbFile,
    required this.useEscaping,
    required this.relaxSyntax,
  });

  const TranslateYamlResults.empty()
      : modelProvider = null,
        apiKey = null,
        vertexAiProjectUrl = null,
        arbDir = null,
        templateArbFile = null,
        useEscaping = null,
        relaxSyntax = null;

  final ModelProvider? modelProvider;
  final String? apiKey;
  final String? vertexAiProjectUrl;
  final String? arbDir;
  final String? templateArbFile;
  final bool? useEscaping;
  final bool? relaxSyntax;
}

class TranslateYamlParser {
  static const _modelProviderKey = 'arb-translate-model-provider';
  static const _apiKeyKey = 'arb-translate-api-key';
  static const _vertexAiProjectUrlKey = 'arb-translate-vertex-ai-project-url';

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
      modelProvider: _tryReadModelProvider(yamlNode, _modelProviderKey),
      arbDir: _tryReadUri(yamlNode, TranslationOptions.arbDirKey)?.path,
      vertexAiProjectUrl:
          _tryReadUri(yamlNode, _vertexAiProjectUrlKey).toString(),
      templateArbFile:
          _tryReadUri(yamlNode, TranslationOptions.templateArbFileKey)?.path,
      apiKey: _tryReadString(yamlNode, _apiKeyKey),
      useEscaping: _tryReadBool(yamlNode, TranslationOptions.useEscapingKey),
      relaxSyntax: _tryReadBool(yamlNode, TranslationOptions.relaxSyntaxKey),
    );
  }

  static ModelProvider? _tryReadModelProvider(YamlMap yamlMap, String key) {
    final value = _tryReadString(yamlMap, key);

    if (value == null) {
      return null;
    }

    return ModelProvider.values.firstWhere(
      (provider) => provider.key == value,
      orElse: () => throw FormatException(
        'Expected "$key" to have a value of "google-ai-studio" or "vertex-ai", instead was "$value"',
      ),
    );
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
}
