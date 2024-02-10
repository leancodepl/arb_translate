import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiTranslationDelegate extends TranslationDelegate {
  GeminiTranslationDelegate({
    required String apiKey,
    required bool useEscaping,
    required bool relaxSyntax,
  })  : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
        ),
        super(
          useEscaping: useEscaping,
          relaxSyntax: relaxSyntax,
        );

  static const _batchSize = 1024;
  static const _maxRetryCount = 5;
  static const _maxParalellQueries = 5;
  static const _queryBackoff = Duration(seconds: 5);

  final GenerativeModel _model;

  @override
  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final batches = prepareBatches(resources);

    final results = <String, String>{};

    for (var i = 0; i < batches.length; i += _maxParalellQueries) {
      final batchResults = await Future.wait(
        [
          for (var j = i;
              j < i + _maxParalellQueries && j < batches.length;
              j++)
            _translateBatch(
              resources: batches[j],
              locale: locale,
              batchName: '${j + 1}/${batches.length}',
            ),
        ],
      );

      results.addAll({for (final results in batchResults) ...results});
    }

    return results;
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

  Future<Map<String, String>> _translateBatch({
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

        if (!validateResults(resources, result)) {
          final retryName = '${retryCount + 1}/$_maxRetryCount';

          print(
            'Placeholder validation failed for batch $batchName, retrying $retryName...',
          );

          retryCount++;

          if (retryCount > _maxRetryCount) {
            throw Exception('Placeholder validation failed');
          }

          continue;
        }

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
