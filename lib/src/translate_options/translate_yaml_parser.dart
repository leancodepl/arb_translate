import 'package:arb_translate/arb_translate.dart';
import 'package:file/file.dart';
import 'package:yaml/yaml.dart';

/// Represents the results of parsing a YAML file for translation options.
class TranslateYamlResults {
  const TranslateYamlResults({
    required this.modelProvider,
    required this.customModelProviderBaseUrl,
    required this.model,
    required this.customModel,
    required this.apiKey,
    required this.vertexAiProjectUrl,
    required this.disableSafety,
    required this.context,
    required this.excludeLocales,
    required this.batchSize,
    required this.arbDir,
    required this.templateArbFile,
    required this.useEscaping,
    required this.relaxSyntax,
  });

  /// Creates an empty instance of [TranslateYamlResults].
  const TranslateYamlResults.empty()
      : modelProvider = null,
        customModelProviderBaseUrl = null,
        model = null,
        customModel = null,
        apiKey = null,
        vertexAiProjectUrl = null,
        disableSafety = null,
        context = null,
        excludeLocales = null,
        batchSize = null,
        arbDir = null,
        templateArbFile = null,
        useEscaping = null,
        relaxSyntax = null;

  /// The model provider for translation.
  final ModelProvider? modelProvider;

  /// The model for translation.
  final Model? model;

  /// The custom model for translation.
  final String? customModel;

  /// The API key for translation.
  final String? apiKey;

  /// The URL of the Vertex AI project.
  final String? vertexAiProjectUrl;

  /// The custom model provider base URL for translation.
  final String? customModelProviderBaseUrl;

  /// Indicates whether safety checks are disabled.
  final bool? disableSafety;

  /// The context for translation.
  final String? context;

  /// The list of locales to exclude from translation.
  final List<String>? excludeLocales;

  /// The target number of characters of messages to send to a model in a single
  /// batch. The actual number can be higher if a single message is too large.
  final int? batchSize;

  /// The directory containing the ARB files.
  final String? arbDir;

  /// The template ARB file.
  final String? templateArbFile;

  /// Indicates whether escaping is used in messages.
  final bool? useEscaping;

  /// Indicates whether relaxed syntax is used in messages.
  final bool? relaxSyntax;
}

/// A class that parses YAML files containing translation options.
class TranslateYamlParser {
  static const _modelProviderKey = 'arb-translate-model-provider';
  static const _modelKey = 'arb-translate-model';
  static const _customModelKey = 'arb-translate-custom-model';
  static const _apiKeyKey = 'arb-translate-api-key';
  static const _vertexAiProjectUrlKey = 'arb-translate-vertex-ai-project-url';
  static const _customModelProviderBaseUrlKey =
      'arb-translate-custom-model-provider-base-url';
  static const _disableSafetyKey = 'arb-translate-disable-safety';
  static const _contextKey = 'arb-translate-context';
  static const _excludeLocalesKey = 'arb-translate-exclude-locales';
  static const _batchSizeKey = 'arb-translate-batch-size';

  /// Parses the given [file] and returns the translation options.
  ///
  /// If the file does not exist or is empty, it returns an empty [TranslateYamlResults] object.
  /// If the file does not contain a YAML map, it throws a [FormatException].
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
      model: _tryReadModel(yamlNode, _modelKey),
      customModel: _tryReadString(yamlNode, _customModelKey),
      arbDir: _tryReadUri(yamlNode, TranslateOptions.arbDirKey)?.path,
      vertexAiProjectUrl:
          _tryReadUri(yamlNode, _vertexAiProjectUrlKey).toString(),
      customModelProviderBaseUrl:
          _tryReadUri(yamlNode, _customModelProviderBaseUrlKey).toString(),
      disableSafety: _tryReadBool(yamlNode, _disableSafetyKey),
      context: _tryReadString(yamlNode, _contextKey),
      excludeLocales: _tryReadStringList(yamlNode, _excludeLocalesKey),
      batchSize: _tryReadInt(yamlNode, _batchSizeKey),
      templateArbFile:
          _tryReadUri(yamlNode, TranslateOptions.templateArbFileKey)?.path,
      apiKey: _tryReadString(yamlNode, _apiKeyKey),
      useEscaping: _tryReadBool(yamlNode, TranslateOptions.useEscapingKey),
      relaxSyntax: _tryReadBool(yamlNode, TranslateOptions.relaxSyntaxKey),
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
        'Expected "$key" to be equal to one of (${ModelProvider.values.map((provider) => provider.key).join(', ')}), instead was "$value"',
      ),
    );
  }

  static Model? _tryReadModel(YamlMap yamlMap, String key) {
    final value = _tryReadString(yamlMap, key);

    if (value == null) {
      return null;
    }

    return Model.values.firstWhere(
      (model) => model.key == value,
      orElse: () => throw FormatException(
        'Expected "$key" to be equal to one of (${Model.values.map((model) => model.key).join(', ')}), instead was "$value"',
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

  static int? _tryReadInt(YamlMap yamlMap, String key) {
    final Object? value = yamlMap[key];

    if (value == null) {
      return null;
    }

    if (value is! int) {
      throw FormatException(
        'Expected "$key" to have a int value, instead was "$value"',
      );
    }

    return value;
  }

  static List<String>? _tryReadStringList(YamlMap yamlMap, String key) {
    final Object? value = yamlMap[key];

    if (value == null) {
      return null;
    }

    if (value is String) {
      return <String>[value];
    }

    if (value is Iterable) {
      return value.map((e) => e.toString()).toList();
    }

    throw FormatException(
        'Expected "$key" to have a String or List value, instead was "$value"');
  }
}
