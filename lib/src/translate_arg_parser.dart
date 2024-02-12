import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:args/args.dart';
import 'package:collection/collection.dart';

class TranslateArgResults {
  const TranslateArgResults({
    required this.help,
    required this.modelProvider,
    required this.apiKey,
    required this.vertexAiProjectUrl,
    required this.arbDir,
    required this.templateArbFile,
    required this.useEscaping,
    required this.relaxSyntax,
  });

  final bool? help;
  final ModelProvider? modelProvider;
  final String? vertexAiProjectUrl;
  final String? apiKey;
  final String? arbDir;
  final String? templateArbFile;
  final bool? useEscaping;
  final bool? relaxSyntax;
}

class TranslateArgParser {
  static const _helpKey = 'help';
  static const _modelProviderKey = 'model-provider';
  static const _apiKeyKey = 'api-key';
  static const _vertexAiProjectUrlKey = 'vertex-ai-project-url';

  final _parser = ArgParser(
      usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null)
    ..addFlag(
      _helpKey,
      abbr: 'h',
      help: 'Print this usage information.',
      negatable: false,
    )
    ..addOption(
      _modelProviderKey,
      help: 'The model provider to use for translation.',
      allowed: ModelProvider.values.map((provider) => provider.key),
      defaultsTo: ModelProvider.gemini.key,
      allowedHelp: {
        ModelProvider.gemini.key: 'Gemini',
        ModelProvider.vertexAi.key:
            'Vertex AI (useful for users in regions where Gemini is unavailable'
                ' such as EU)',
      },
    )
    ..addOption(
      _apiKeyKey,
      help: 'API key used to make translation requests.',
    )
    ..addOption(
      _vertexAiProjectUrlKey,
      help: 'The URL of the Vertex AI project to use for translation.',
    )
    ..addSeparator('ARB options:')
    ..addOption(
      TranslationOptions.arbDirKey,
      help: 'The directory where the template and translated arb files are '
          'located.',
    )
    ..addOption(
      TranslationOptions.templateArbFileKey,
      help: 'The template arb file that will be used as the basis for '
          'translation.',
    )
    ..addFlag(
      TranslationOptions.useEscapingKey,
      help: 'Whether or not to use escaping for messages.\n'
          '\n'
          'By default, this value is set to false for backwards compatibility. '
          'Turning this flag on will cause the parser to treat any special '
          'characters contained within pairs of single quotes as normal '
          'strings and treat all consecutive pairs of single quotes as a '
          'single quote character.',
    )
    ..addFlag(
      TranslationOptions.relaxSyntaxKey,
      help: 'When specified, the syntax will be relaxed so that the special '
          'character "{" is treated as a string if it is not followed by a '
          'valid placeholder and "}" is treated as a string if it does not '
          'close any previous "{" that is treated as a special character.',
    );

  String get usage => _parser.usage;

  TranslateArgResults parse(List<String> args) {
    final rawResults = _parser.parse(args);

    if (rawResults.rest.isNotEmpty) {
      throw FormatException(
        'Unexpected positional argument "${rawResults.rest.first}".',
      );
    }

    return TranslateArgResults(
      help: rawResults[_helpKey] as bool?,
      modelProvider: ModelProvider.values.firstWhereOrNull(
        (provider) => provider.key == rawResults[_modelProviderKey],
      ),
      apiKey: rawResults[_apiKeyKey] as String?,
      vertexAiProjectUrl: rawResults[_vertexAiProjectUrlKey] as String?,
      arbDir: rawResults[TranslationOptions.arbDirKey] as String?,
      templateArbFile:
          rawResults[TranslationOptions.templateArbFileKey] as String?,
      useEscaping: rawResults[TranslationOptions.useEscapingKey] as bool?,
      relaxSyntax: rawResults[TranslationOptions.relaxSyntaxKey] as bool?,
    );
  }
}
