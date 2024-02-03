import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';
import 'package:flutter_tools/src/localizations/localizations_utils.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class TranslateCommand extends Command {
  TranslateCommand() {
    argParser.addOption(
      'arb-dir',
      help:
          'The directory where the template and translated arb files are located.',
    );
    argParser.addOption(
      'template-arb-file',
      help: 'The template arb file that will be used as the basis for '
          'generating the Dart localization and messages files.',
    );
    argParser.addOption(
      'untranslated-messages-file',
      help: 'The location of a file that describes the localization '
          'messages have not been translated yet. Using this option will create '
          'a JSON file at the target location, in the following format:\n'
          '\n'
          '    "locale": ["message_1", "message_2" ... "message_n"]\n'
          '\n'
          'If this option is not specified, a summary of the messages that '
          'have not been translated will be printed on the command line.',
    );
    argParser.addOption('project-dir',
        valueHelp: 'absolute/path/to/flutter/project',
        help: 'When specified, the tool uses the path passed into this option '
            'as the directory of the root Flutter project.\n'
            '\n'
            'When null, the relative path to the present working directory will be used.');
  }

  @override
  String get description => 'Translate terms for the current project.';

  @override
  String get name => 'translate';

  @override
  Future<void> run() async {
    final arbDir = '/Users/robert/Documents/inktica/app/lib/l10n';
    final templateArbFile = 'app_en.arb';
    final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: Platform.environment['GOOGLE_AI_API_KEY']!);

    final allBundles =
        AppResourceBundleCollection(LocalFileSystem().directory(arbDir));
    final templateBundle =
        AppResourceBundle(LocalFileSystem().file('$arbDir/$templateArbFile'));

    final resourcesToTranslate = <LocaleInfo, List<String>>{};

    for (final bundle in allBundles.bundles) {
      final locale = bundle.locale;

      final untranslatedMessageIds = templateBundle.resourceIds.where((id) =>
          !bundle.resources.containsKey(id) ||
          (bundle.resources[id] as String).isEmpty);

      if (untranslatedMessageIds.isEmpty) {
        continue;
      }

      resourcesToTranslate[locale] = untranslatedMessageIds.toList();
    }

    for (final localeResoucesToTranslate in resourcesToTranslate.entries) {
      final locale = localeResoucesToTranslate.key;
      final resourceIds = localeResoucesToTranslate.value;

      print('Translating ${resourceIds.length} terms for $locale...');

      final content = [
        Content.text(
          // ignore: prefer_interpolation_to_compose_strings
          'Translate the following terms to ${locale.languageCode}\n' +
              json.encode(
                {
                  for (final id in resourceIds)
                    id: templateBundle.resources[id] as String,
                },
              ),
        ),
      ];
      final response = await model.generateContent(content);

      final result = json.decode(response.text!) as Map<String, dynamic>;

      final bundle =
          allBundles.bundles.firstWhere((bundle) => bundle.locale == locale);

      final outputFile = bundle.file;

      final encoder = JsonEncoder.withIndent('  ');

      await outputFile.writeAsString(
        encoder.convert(
          {
            for (final id in templateBundle.resourceIds)
              id: result[id] ?? bundle.resources[id] as String
          },
        ),
      );
    }
  }
}
