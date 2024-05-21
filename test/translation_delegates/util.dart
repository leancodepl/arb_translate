import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';

const context = 'sporting goods store app';

const resources = {
  "months": "{count, plural, one{1 month} other{{count} months}}",
  "@months": {
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "bat": "Bat"
};

Future<void> tryTranslateWithDelegate(TranslationDelegate delegate) {
  return delegate.translate(
    resources,
    LocaleInfo.fromString('pl'),
  );
}
