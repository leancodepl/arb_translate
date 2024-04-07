import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translate_exception.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart';

class InvalidApiKeyException implements TranslateException {
  @override
  String get message => 'Provided API key is not valid';
}

class UnsupportedUserLocationException implements TranslateException {
  @override
  String get message => 'Gemini API is not available in your location. Use '
      'Vertex AI model provider. See the documentation for more information';
}

class SafetyException implements TranslateException {
  @override
  String get message =>
      'Translation failed due to safety settings. You can disable safety '
      'settings using --disable-safety flag or with '
      'arb-translate-disable-safety: true in l10n.yaml';
}

class ResponseParsingException implements TranslateException {
  @override
  String get message => 'Failed to parse API response';
}

class PlaceholderValidationException implements TranslateException {
  @override
  String get message => 'Placeholder validation failed';
}

class GeminiTranslationDelegate extends TranslationDelegate {
  GeminiTranslationDelegate({
    required String apiKey,
    required super.context,
    required bool disableSafety,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
          safetySettings: disableSafety ? _disabledSafetySettings : [],
        );

  GeminiTranslationDelegate.vertexAi({
    required String apiKey,
    required String projectUrl,
    required super.context,
    required bool disableSafety,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = GenerativeModel(
          model: 'gemini-pro',
          apiKey: apiKey,
          safetySettings: disableSafety ? _disabledSafetySettings : [],
          httpClient: VertexHttpClient(projectUrl),
        );

  static const _batchSize = 4096;
  static const _maxRetryCount = 5;
  static const _maxParallelQueries = 5;
  static const _queryBackoff = Duration(seconds: 5);

  static final _disabledSafetySettings = [
    HarmCategory.harassment,
    HarmCategory.hateSpeech,
    HarmCategory.sexuallyExplicit,
    HarmCategory.dangerousContent,
  ]
      .map((category) => SafetySetting(category, HarmBlockThreshold.none))
      .toList();

  final GenerativeModel _model;

  @override
  Future<Map<String, String>> translate(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final batches = prepareBatches(resources);

    final results = <String, String>{};

    for (var i = 0; i < batches.length; i += _maxParallelQueries) {
      final batchResults = await Future.wait(
        [
          for (var j = i;
              j < i + _maxParallelQueries && j < batches.length;
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
        'Translate ARB messages for ${context ?? 'app'} to locale "$locale". '
        'Add other ICU plural forms according to CLDR rules if necessary.\n\n'
        '$encodedResources',
      ),
    ];

    var retryCount = 0;

    while (true) {
      String? response;

      try {
        response = (await _model.generateContent(prompt)).text;
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
      } on ServerException catch (e) {
        if (e.message
            .startsWith('Request had invalid authentication credentials.')) {
          throw InvalidApiKeyException();
        }

        rethrow;
      } on UnsupportedUserLocation catch (_) {
        throw UnsupportedUserLocationException();
      } on GenerativeAIException catch (e) {
        if (e.message.startsWith('Candidate was blocked due to safety')) {
          throw SafetyException();
        }

        rethrow;
      }

      final result = _tryParseResponse(resources, response);

      if (result == null) {
        retryCount++;

        if (retryCount > _maxRetryCount) {
          throw ResponseParsingException();
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
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    if (!url
        .toString()
        .contains('https://generativelanguage.googleapis.com/v1/models')) {
      return _client.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );
    }

    final response = await _client.post(
      Uri.parse(url.toString().replaceAll(
          'https://generativelanguage.googleapis.com/v1/models', _projectUrl)),
      headers: {
        ...Map.fromEntries(
            headers?.entries.where((entry) => entry.key != 'x-goog-api-key') ??
                []),
        'Authorization': 'Bearer ${headers?['x-goog-api-key']}'
      },
      body: body,
      encoding: encoding,
    );

    if (response.statusCode != 200) {
      return response;
    }

    final responseBody = response.body;
    dynamic parsedRespnoseBody;

    try {
      parsedRespnoseBody = json.decode(responseBody);
    } catch (_) {
      return response;
    }

    // We have to rewrite the `citations` to `citationsources` because of
    // incompatibility between Gemini and Vertex AI. Vertext AI returns
    // `citations` instead of `citationSources`.
    if (parsedRespnoseBody is Map<String, dynamic>) {
      final candidates = parsedRespnoseBody['candidates'];

      if (candidates is List) {
        for (final candidate in candidates) {
          if (candidate is Map<String, dynamic>) {
            final citationMetadata = candidate['citationMetadata'];

            if (citationMetadata is Map<String, dynamic>) {
              citationMetadata['citationSources'] =
                  citationMetadata['citations'];
            }
          }
        }
      }
    }

    return Response(
      json.encode(parsedRespnoseBody),
      response.statusCode,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) => _client.send(request);
}
