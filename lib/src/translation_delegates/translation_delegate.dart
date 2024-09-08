import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/fakes/fake_app_resource_bundle.dart';
import 'package:arb_translate/src/flutter_tools/fakes/fake_app_resource_bundle_collection.dart';
import 'package:arb_translate/src/flutter_tools/gen_l10n_types.dart';
import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translation_delegates/translate_exception.dart';
import 'package:meta/meta.dart';

abstract class TranslationDelegate {
  const TranslationDelegate({
    required this.batchSize,
    required this.context,
    required this.useEscaping,
    required this.relaxSyntax,
  });

  final int batchSize;
  final String? context;
  final bool useEscaping;
  final bool relaxSyntax;

  int get maxRetryCount;
  int get maxParallelQueries;
  Duration get queryBackoff;

  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final batches = prepareBatches(resources);

    final results = <String, String>{};

    for (var i = 0; i < batches.length; i += maxParallelQueries) {
      final batchResults = await Future.wait(
        [
          for (var j = i; j < i + maxParallelQueries && j < batches.length; j++)
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

      if (lastBatchSize == 0 || lastBatchSize + resourceSize <= batchSize) {
        batches.last.addAll(resourceWithMetadata);

        lastBatchSize += resourceSize;
      } else {
        batches.add(resourceWithMetadata);

        lastBatchSize = resourceSize;
      }
    }

    return batches;
  }

  Future<Map<String, String>> _translateBatch({
    required Map<String, Object?> resources,
    required LocaleInfo locale,
    required String batchName,
  }) async {
    var retryCount = 0;

    while (true) {
      String response;

      try {
        response = await getModelResponse(resources, locale);
      } on QuotaExceededException {
        print(
          'Quota exceeded for batch $batchName, retrying in '
          '${queryBackoff.inSeconds}s...',
        );

        await Future.delayed(queryBackoff);
        continue;
      } on NoResponseException catch (_) {
        retryCount++;

        print(
          'Placeholder validation failed for batch $batchName, retrying '
          '$retryCount/$maxRetryCount...',
        );

        if (retryCount > maxRetryCount) {
          rethrow;
        }

        continue;
      }

      final result = _tryParseResponse(resources, response);

      if (result == null) {
        retryCount++;

        if (retryCount > maxRetryCount) {
          throw ResponseParsingException();
        }

        print(
          'Failed to parse response for $batchName, retrying '
          '$retryCount/$maxRetryCount...',
        );

        continue;
      }

      if (!validateResults(resources, result)) {
        retryCount++;

        print(
          'Placeholder validation failed for batch $batchName, retrying '
          '$retryCount/$maxRetryCount...',
        );

        if (retryCount > maxRetryCount) {
          throw PlaceholderValidationException();
        }

        continue;
      }

      print('Translated batch $batchName');

      return result;
    }
  }

  Future<String> getModelResponse(
    Map<String, Object?> resources,
    LocaleInfo locale,
  );

  Map<String, String>? _tryParseResponse(
    Map<String, Object?> resources,
    String? response,
  ) {
    if (response == null) {
      return null;
    }

    final trimmedResponse = response.substring(
        response.indexOf('{'), response.lastIndexOf('}') + 1);

    Map<String, Object?> responseJson;

    try {
      responseJson = json.decode(trimmedResponse);
    } catch (e) {
      return null;
    }

    final messageResources =
        resources.keys.where((key) => !key.startsWith('@'));

    if (messageResources.any((key) => responseJson[key] is! String)) {
      return null;
    }

    return {
      for (final key in messageResources) key: responseJson[key] as String,
    };
  }

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
