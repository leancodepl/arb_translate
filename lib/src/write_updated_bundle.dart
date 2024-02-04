// ignore_for_file: implementation_imports

import 'dart:convert';

import 'package:flutter_tools/src/localizations/gen_l10n_types.dart';

Future<void> writeUpdatedBundle(
  AppResourceBundle bundle,
  AppResourceBundle templateBundle,
  Map<String, String> translationResult,
) {
  return bundle.file.writeAsString(
    JsonEncoder.withIndent('  ').convert(
      {
        ...Map.fromEntries(bundle.resources.entries
            .where((entry) => entry.key.startsWith('@@'))),
        for (final id in templateBundle.resourceIds)
          id: translationResult[id] ?? bundle.resources[id] as String
      },
    ),
  );
}
