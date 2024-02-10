import 'package:arb_translate/src/translation_options.dart';
import 'package:args/args.dart';

ArgResults parseArgs(List<String> arguments) {
  final parser = ArgParser()
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
    ..addOption(
      TranslationOptions.geminiApiKeyKey,
      help: 'Gemini API key used to make translation requests.',
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

  final results = parser.parse(arguments);

  if (results.rest.isNotEmpty) {
    throw Exception(
      'Unexpected positional argument "${results.rest.first}".',
    );
  }

  return results;
}
