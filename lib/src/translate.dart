import 'package:arb_translate/src/find_untranslated_resource_ids.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/prepare_untranslated_resources.dart';
import 'package:arb_translate/src/translation_delegate.dart';
import 'package:arb_translate/src/translation_options.dart';
import 'package:arb_translate/src/write_updated_bundle.dart';
import 'package:file/file.dart';

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
