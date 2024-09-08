import 'dart:io';

import 'package:arb_translate/src/find_untranslated_resource_ids.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/prepare_untranslated_resources.dart';
import 'package:arb_translate/src/translation_delegates/translate_exception.dart';
import 'package:arb_translate/src/translate_options/translate_options.dart';
import 'package:arb_translate/src/translation_delegates/chat_gpt_translation_delegate.dart';
import 'package:arb_translate/src/translation_delegates/gemini_translation_delegate.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:arb_translate/src/write_updated_bundle.dart';
import 'package:file/file.dart';

/// Translates the ARB files in the specified directory using the given options.
///
/// The [fileSystem] parameter represents the file system to use for accessing
/// the ARB files.
/// The [options] parameter contains the translation options, including the
/// model provider, API key, context, safety settings, and more.
Future<void> translate(
  FileSystem fileSystem,
  TranslateOptions options,
) async {
  final translationDelegate = switch (options.modelProvider) {
    ModelProvider.gemini => GeminiTranslationDelegate(
        model: options.model,
        apiKey: options.apiKey,
        batchSize: options.batchSize,
        context: options.context,
        disableSafety: options.disableSafety,
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
    ModelProvider.vertexAi => GeminiTranslationDelegate.vertexAi(
        model: options.model,
        apiKey: options.apiKey,
        projectUrl: options.vertexAiProjectUrl!,
        batchSize: options.batchSize,
        context: options.context,
        disableSafety: options.disableSafety,
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
    ModelProvider.openAi => ChatGptTranslationDelegate(
        model: options.model,
        apiKey: options.apiKey,
        batchSize: options.batchSize,
        context: options.context,
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
    ModelProvider.customOpenAiCompatible => ChatGptTranslationDelegate.custom(
        model: options.customModel!,
        apiKey: options.apiKey,
        baseUrl: options.customModelProviderBaseUrl!,
        batchSize: options.batchSize,
        context: options.context,
        useEscaping: options.useEscaping,
        relaxSyntax: options.relaxSyntax,
      ),
  };

  final bundles =
      AppResourceBundleCollection(fileSystem.directory(options.arbDir)).bundles;
  final templateBundle = bundles.firstWhere(
      (bundle) => bundle.file.path.endsWith(options.templateArbFile));

  for (final bundle in bundles.where((bundle) => bundle != templateBundle)) {
    if (options.excludeLocales?.contains(bundle.locale.toString()) ?? false) {
      print('Skiping excluded locale ${bundle.locale}');

      continue;
    }

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
  } on TranslateException catch (e) {
    print(e.message);
    exit(1);
  }

  await writeUpdatedBundle(bundle, templateBundle, translationResult);
}
