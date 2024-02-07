import 'dart:convert';

import 'package:arb_gpt_translator/src/flutter_tools/localizations_utils.dart';
import 'package:collection/collection.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

abstract class TranslationDelegate {
  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  );
}

class GeminiTranslationDelegate implements TranslationDelegate {
  GeminiTranslationDelegate(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        );

  static const _batchSize = 1024;
  static const _maxRetryCount = 5;
  static const _queryBackoff = Duration(seconds: 5);

  final GenerativeModel _model;

  @override
  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final batches = prepareBatches(resources);

    final results = await Future.wait(
      batches.mapIndexed(
        (index, batch) => translateBatch(
          resources: batch,
          locale: locale,
          batchName: '${index + 1}/${batches.length}',
        ),
      ),
    );

    return {for (final result in results) ...result};
  }

  List<Map<String, Object?>> prepareBatches(Map<String, Object?> resources) {
    final batches = [<String, Object?>{}];

    var lastBatchSize = 0;

    for (final key in resources.keys.where((key) => !key.startsWith('@'))) {
      final resourceWithMetadata = {
        key: resources[key],
        if (resources.containsKey('@$key')) '@$key': resources['@$key'],
      };
      final resourceSize = json.encode(resourceWithMetadata).length;

      if (lastBatchSize + resourceSize <= _batchSize) {
        batches.last.addAll(resourceWithMetadata);

        lastBatchSize += resourceSize;
      } else {
        batches.add(resourceWithMetadata);

        lastBatchSize = key.length;
      }
    }

    return batches;
  }

  Future<Map<String, String>> translateBatch({
    required Map<String, Object?> resources,
    required LocaleInfo locale,
    required String batchName,
  }) async {
    final encodedResources = JsonEncoder.withIndent('  ').convert(resources);
    final prompt = [
      Content.text(
        'Translate the terms below to locale "$locale". Terms are in ARB format. '
        'Add other ICU plural forms according to CLDR rules if necessary\n'
        '$encodedResources',
      ),
    ];

    var retryCount = 0;

    while (true) {
      try {
        final response = await _model.generateContent(prompt);
        final responseJson =
            json.decode(response.text!) as Map<String, Object?>;
        final result = {
          for (final key in resources.keys.where((key) => !key.startsWith('@')))
            key: responseJson[key] as String,
        };

        print('Translated batch $batchName');

        return result;
      } catch (e) {
        final retryName = '${retryCount + 1}/$_maxRetryCount';

        if (e is FormatException && e.message.contains('code: 429')) {
          print(
            'Quota exceeded for batch $batchName, retrying $retryName in '
            '${_queryBackoff.inSeconds}s...',
          );

          await Future.delayed(_queryBackoff);
        } else {
          print(
            'Failed to translate batch $batchName, retrying $retryName...',
          );

          retryCount++;
        }

        if (retryCount > _maxRetryCount) {
          rethrow;
        }
      }
    }
  }
}
