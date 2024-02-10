import 'package:arb_translate/src/flutter_tools/fakes/fake_app_resource_bundle.dart';
import 'package:arb_translate/src/flutter_tools/fakes/fake_app_resource_bundle_collection.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:meta/meta.dart';

abstract class TranslationDelegate {
  const TranslationDelegate({
    required this.useEscaping,
    required this.relaxSyntax,
  });

  final bool useEscaping;
  final bool relaxSyntax;

  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  );

  @protected
  @visibleForTesting
  bool validateResults(
    Map<String, Object?> resources,
    Map<String, String> results,
  ) {
    final templateBundle = FakeAppResourcesBundle(resources, true);
    final otherBundle = FakeAppResourcesBundle(results, false);

    for (final key in resources.keys.where((key) => !key.startsWith('@'))) {
      try {
        final message = Message(
          templateBundle,
          FakeAppResourceBundleCollection(
            templateBundle: templateBundle,
            otherBundle: otherBundle,
          ),
          key,
          false,
          useEscaping: useEscaping,
          useRelaxedSyntax: relaxSyntax,
        );

        if (message.hadErrors) {
          return false;
        }
      } catch (e) {
        return false;
      }
    }

    return true;
  }
}
