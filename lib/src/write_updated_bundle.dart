import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';

Future<void> writeUpdatedBundle(
  AppResourceBundle bundle,
  AppResourceBundle templateBundle,
  Map<String, String> translationResult,
) {
  return bundle.file.writeAsString(
    JsonEncoder.withIndent('  ').convert({
      ...Map.fromEntries(
        bundle.resources.entries.where((entry) => entry.key.startsWith('@@')),
      ),
      for (final id in templateBundle.resourceIds)
        id: translationResult[id] ?? bundle.resources[id] as String,
    }),
  );
}
