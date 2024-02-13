import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart';

class InvalidApiKeyException implements Exception {
  String get message => 'Provided API key is not valid';
}

class UnsupportedUserLocationException implements Exception {
  String get message => 'Gemini API is not avilable in your location';
}

class ReponseParsingException implements Exception {
  String get message => 'Failed to parse API response';
}

class PlaceholderValidationException implements Exception {
  String get message => 'Placeholder validation failed';
}

class GeminiTranslationDelegate extends TranslationDelegate {
  GeminiTranslationDelegate({
    required String apiKey,
    required bool useEscaping,
    required bool relaxSyntax,
  })  : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
          httpClient: null,
        ),
        _useVertexAi = false,
        super(
          useEscaping: useEscaping,
          relaxSyntax: relaxSyntax,
        );

  GeminiTranslationDelegate.vertexAi({
    required String apiKey,
    required String projectUrl,
    required bool useEscaping,
    required bool relaxSyntax,
  })  : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
          httpClient: VertexHttpClient(projectUrl),
        ),
        _useVertexAi = true,
        super(
          useEscaping: useEscaping,
          relaxSyntax: relaxSyntax,
        );

  static const _batchSize = 4096;
  static const _maxRetryCount = 5;
  static const _maxParalellQueries = 5;
  static const _queryBackoff = Duration(seconds: 5);

  final GenerativeModel _model;
  final bool _useVertexAi;

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
      String? response;

      try {
        // For Vertex AI we have to use `generateContentStream` method because
        // generateContent doesn't respect http client we provide
        // https://github.com/google/generative-ai-dart/issues/64
        if (_useVertexAi) {
          response = await _model
              .generateContentStream(prompt)
              .map((contentResponse) => contentResponse.text ?? '')
              .join();
        } else {
          response = (await _model.generateContent(prompt)).text;
        }
      } on FormatException catch (e) {
        if (e.message.contains('code: 429')) {
          print(
            'Quota exceeded for batch $batchName, retrying in '
            '${_queryBackoff.inSeconds}s...',
          );

          await Future.delayed(_queryBackoff);
        } else {
          retryCount++;

          if (retryCount > _maxRetryCount) {
            rethrow;
          }

          print(
            'Failed to fetch translations for $batchName, retrying '
            '$retryCount/$_maxRetryCount...',
          );
        }

        continue;
      } on InvalidApiKey catch (_) {
        throw InvalidApiKeyException();
      } on UnsupportedUserLocation catch (_) {
        throw UnsupportedUserLocationException();
      }

      final result = _tryParseResponse(resources, response);

      if (result == null) {
        retryCount++;

        if (retryCount > _maxRetryCount) {
          throw ReponseParsingException();
        }

        print(
          'Failed to parse response for $batchName, retrying '
          '$retryCount/$_maxRetryCount...',
        );

        continue;
      }

      if (!validateResults(resources, result)) {
        retryCount++;

        print(
          'Placeholder validation failed for batch $batchName, retrying '
          '$retryCount/$_maxRetryCount...',
        );

        if (retryCount > _maxRetryCount) {
          throw PlaceholderValidationException();
        }

        continue;
      }

      print('Translated batch $batchName');

      return result;
    }
  }

  Map<String, String>? _tryParseResponse(
    Map<String, Object?> resources,
    String? response,
  ) {
    if (response == null) {
      return null;
    }

    Map<String, Object?> responseJson;

    try {
      responseJson = json.decode(response);
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
}

class VertexHttpClient extends BaseClient {
  VertexHttpClient(this._projectUrl);

  final String _projectUrl;
  final _client = Client();

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (request is! Request ||
        request.url.host != 'generativelanguage.googleapis.com') {
      return _client.send(request);
    }

    final vertexRequest = Request(
        request.method,
        Uri.parse(request.url.toString().replaceAll(
            'https://generativelanguage.googleapis.com/v1/models',
            _projectUrl)))
      ..bodyBytes = request.bodyBytes;

    for (final header in request.headers.entries) {
      if (header.key != 'x-goog-api-key') {
        vertexRequest.headers[header.key] = header.value;
      }
    }

    vertexRequest.headers['Authorization'] =
        'Bearer ${request.headers['x-goog-api-key']}';

    final response = await _client.send(vertexRequest);

    // `generateContentStream` method doesn't parse errors correctly. We have to
    // handle at least invalid API key case so we have to handle it here.
    if (response.statusCode == 401) {
      throw InvalidApiKey('Invalid API Key');
    }

    return response;
  }
}
