import 'package:arb_translate/arb_translate.dart';
import 'package:file/local.dart';

Future<void> main(List<String> arguments) async {
  final fileSystem = LocalFileSystem();
  final argResults = parseArgs(arguments);
  final options = TranslationOptions.parse(fileSystem, argResults);

  await translate(fileSystem, options);
}
