import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';

List<String> findUntranslatedResourceIds(
  AppResourceBundle bundle,
  AppResourceBundle templateBundle,
) {
  final untranslatedMessageIds = templateBundle.resourceIds.where(
    (id) =>
        !bundle.resources.containsKey(id) ||
        (bundle.resources[id] as String).isEmpty,
  );

  return untranslatedMessageIds.toList();
}
