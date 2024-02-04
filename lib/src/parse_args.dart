import 'package:arb_gpt_translator/src/translation_options.dart';
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
    );

  final results = parser.parse(arguments);

  if (results.rest.isNotEmpty) {
    throw Exception(
      'Unexpected positional argument "${results.rest.first}".',
    );
  }

  return results;
}
