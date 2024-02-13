import 'dart:io';

import 'package:arb_translate/src/find_untranslated_resource_ids.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/prepare_untranslated_resources.dart';
import 'package:arb_translate/src/translation_delegates/gemini_translation_delegate.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:arb_translate/src/translation_options.dart';
import 'package:arb_translate/src/write_updated_bundle.dart';
import 'package:file/file.dart';

Future<void> translate(
  FileSystem fileSystem,
  TranslationOptions options,
) async {
  final translationDelegate = switch (options.modelProvider) {
    ModelProvider.gemini => GeminiTranslationDelegate(
        apiKey: options.apiKey,
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
    ModelProvider.vertexAi => GeminiTranslationDelegate.vertexAi(
        apiKey: options.apiKey,
        projectUrl: options.vertexAiProjectUrl.toString(),
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
  };

  final bundles =
      AppResourceBundleCollection(fileSystem.directory(options.arbDir)).bundles;
  final templateBundle = bundles.firstWhere(
      (bundle) => bundle.file.path.endsWith(options.templateArbFile));

  for (final bundle in bundles.where((bundle) => bundle != templateBundle)) {
    await _translateBundle(
      translationDelegate: translationDelegate,
      templateBundle: templateBundle,
      bundle: bundle,
    );
  }
}

Future<void> _translateBundle({
  required TranslationDelegate translationDelegate,
  required AppResourceBundle templateBundle,
  required AppResourceBundle bundle,
}) async {
  final untranslatedResourceIds =
      findUntranslatedResourceIds(bundle, templateBundle);

  if (untranslatedResourceIds.isEmpty) {
    print('No terms to translate for locale ${bundle.locale}');

    return;
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

  Map<String, String> translationResult;

  try {
    translationResult = await translationDelegate.translate(
      untranslatedResources,
      bundle.locale,
    );
  } on InvalidApiKeyException catch (e) {
    print(e.message);
    exit(1);
  } on UnsupportedUserLocationException catch (e) {
    print(e.message);
    exit(1);
  } on ReponseParsingException catch (e) {
    print(e.message);
    exit(1);
  } on PlaceholderValidationException catch (e) {
    print(e.message);
    exit(1);
  }

  await writeUpdatedBundle(bundle, templateBundle, translationResult);
}
