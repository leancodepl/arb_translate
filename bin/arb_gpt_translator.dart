import 'package:arb_gpt_translator/arb_gpt_translator.dart';
import 'package:file/local.dart';

Future<void> main(List<String> arguments) async {
  final fileSystem = LocalFileSystem();
  final argResults = parseArgs(arguments);
  final options = TranslationOptions.parse(fileSystem, argResults);

  await translate(fileSystem, options);
}
