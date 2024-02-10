import 'package:arb_translate/src/flutter_tools/fakes/fake_app_resource_bundle.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';

class FakeAppResourceBundleCollection implements AppResourceBundleCollection {
  const FakeAppResourceBundleCollection({
    required this.templateBundle,
    required this.otherBundle,
  });

  final FakeAppResourcesBundle templateBundle;
  final FakeAppResourcesBundle otherBundle;

  @override
  AppResourceBundle? bundleFor(LocaleInfo locale) {
    throw UnimplementedError();
  }

  @override
  Iterable<AppResourceBundle> get bundles => [
        templateBundle,
        otherBundle,
      ];

  @override
  Iterable<String> get languages => throw UnimplementedError();

  @override
  Iterable<LocaleInfo> get locales => throw UnimplementedError();

  @override
  Iterable<LocaleInfo> localesForLanguage(String language) {
    throw UnimplementedError();
  }
}
