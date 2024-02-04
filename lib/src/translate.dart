// ignore_for_file: implementation_imports

import 'package:arb_gpt_translator/src/find_untranslated_resource_ids.dart';
import 'package:arb_gpt_translator/src/prepare_untranslated_resources.dart';
import 'package:arb_gpt_translator/src/translation_delegate.dart';
import 'package:arb_gpt_translator/src/translation_options.dart';
import 'package:arb_gpt_translator/src/write_updated_bundle.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';

Future<void> translate(
  FileSystem fileSystem,
  TranslationOptions options,
) async {
  final translationDelegate = GeminiTranslationDelegate(options.geminiApiKey);

  final bundles =
      AppResourceBundleCollection(fileSystem.directory(options.arbDir)).bundles;
  final templateBundle = bundles.firstWhere(
      (bundle) => bundle.file.path.endsWith(options.templateArbFile));

  for (final bundle in bundles.where((bundle) => bundle != templateBundle)) {
    final untranslatedResourceIds =
        findUntranslatedResourceIds(bundle, templateBundle);

    if (untranslatedResourceIds.isEmpty) {
      print(
        'No terms to translate for locale ${bundle.locale}',
      );

      continue;
    } else {
      print(
        'Translating ${untranslatedResourceIds.length} terms for locale '
        '${bundle.locale}...',
      );
    }

    final untranslatedResources = prepareUntranslatedResources(
      templateBundle,
      untranslatedResourceIds,
    );

    final translationResult = await translationDelegate.translate(
      untranslatedResources,
      bundle.locale,
    );

    await writeUpdatedBundle(bundle, templateBundle, translationResult);
  }
}
