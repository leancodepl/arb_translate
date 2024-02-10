import 'package:arb_translate/src/flutter_tools/fakes/fake_file.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:file/file.dart';

class FakeAppResourcesBundle implements AppResourceBundle {
  const FakeAppResourcesBundle(
    this.resources,
    this.isTemplate,
  );

  static const _templateBundleLanguageCode = 'tm';
  static const _otherBundleLanguageCode = 'ot';

  @override
  final Map<String, Object?> resources;
  final bool isTemplate;

  String get _languageCode =>
      isTemplate ? _templateBundleLanguageCode : _otherBundleLanguageCode;

  @override
  File get file => FakeFile();

  @override
  LocaleInfo get locale {
    return LocaleInfo(
      languageCode: _languageCode,
      scriptCode: null,
      countryCode: null,
      length: _languageCode.length,
      originalString: _languageCode,
    );
  }

  @override
  Iterable<String> get resourceIds => throw UnimplementedError();

  @override
  String? translationFor(String resourceId) => resources[resourceId] as String?;
}
