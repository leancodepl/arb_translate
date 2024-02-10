import 'dart:io';

import 'package:arb_translate/arb_translate.dart';
import 'package:file/local.dart';

Future<void> main(List<String> arguments) async {
  final fileSystem = LocalFileSystem();
  final yamlParser = TranslateYamlParser();
  final argParser = TranslateArgParser();

  TranslateYamlResults yamlResults;
  TranslateArgResults argResults;

  try {
    yamlResults = yamlParser.parse(fileSystem.file('l10n.yaml'));
    argResults = argParser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    exit(1);
  }

  if (argResults.help ?? false) {
    print(argParser.usage);
    exit(0);
  }

  TranslationOptions options;

  try {
    options = TranslationOptions.resolve(
      fileSystem,
      yamlResults,
      argResults,
    );
  } on MissingGeminiApiKeyException catch (e) {
    print(e.message);
    exit(1);
  }

  await translate(fileSystem, options);
}
