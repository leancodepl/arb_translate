import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';

Map<String, dynamic> prepareUntranslatedResources(
  AppResourceBundle templateBundle,
  List<String> untranslatedResourceIds,
) {
  return {
    for (final id in untranslatedResourceIds) ...{
      id: templateBundle.resources[id],
      if (templateBundle.resources.containsKey('@$id'))
        '@$id': templateBundle.resources['@$id'],
    },
  };
}
