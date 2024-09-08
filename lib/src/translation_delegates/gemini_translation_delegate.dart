import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translate_options/translate_options.dart';
import 'package:arb_translate/src/translation_delegates/translate_exception.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart';

class GeminiTranslationDelegate extends TranslationDelegate {
  GeminiTranslationDelegate({
    required Model model,
    required String apiKey,
    required super.batchSize,
    required super.context,
    required bool disableSafety,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = GenerativeModel(
          model: switch (model) {
            Model.gemini10Pro => Model.gemini10Pro.key,
            Model.gemini15Pro || Model.gemini15Flash => '${model.key}-latest',
            _ => throw ArgumentError.value(model),
          },
          apiKey: apiKey,
          safetySettings: disableSafety ? _disabledSafetySettings : [],
        );

  GeminiTranslationDelegate.vertexAi({
    required Model model,
    required String apiKey,
    required Uri projectUrl,
    required super.batchSize,
    required super.context,
    required bool disableSafety,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = GenerativeModel(
          model: switch (model) {
            Model.gemini10Pro => Model.gemini10Pro.key,
            Model.gemini15Pro ||
            Model.gemini15Flash =>
              '${model.key}-preview-0514',
            _ => throw ArgumentError.value(model),
          },
          apiKey: apiKey,
          safetySettings: disableSafety ? _disabledSafetySettings : [],
          httpClient: VertexHttpClient(projectUrl.toString()),
        );

  @override
  int get maxRetryCount => 5;
  @override
  int get maxParallelQueries => 5;
  @override
  Duration get queryBackoff => Duration(seconds: 5);

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
  Future<String> getModelResponse(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final encodedResources = JsonEncoder.withIndent('  ').convert(resources);
    final prompt = [
      Content.text(
        'Translate ARB messages for ${context ?? 'app'} to locale "$locale". '
        'Add other ICU plural forms according to CLDR rules if necessary. '
        'Return only raw JSON.\n\n'
        '$encodedResources',
      ),
    ];

    try {
      final response = (await _model.generateContent(prompt)).text;

      if (response == null) {
        throw NoResponseException();
      }

      return response;
    } on FormatException catch (e) {
      if (e.message.contains('code: 429')) {
        throw QuotaExceededException();
      }

      rethrow;
    } on InvalidApiKey catch (_) {
      throw InvalidApiKeyException();
    } on ServerException catch (e) {
      if (e.message
          .startsWith('Request had invalid authentication credentials.')) {
        throw InvalidApiKeyException();
      } else if (e.message.startsWith('Quota exceeded') ||
          e.message.startsWith('Resource has been exhausted')) {
        throw QuotaExceededException();
      }

      rethrow;
    } on UnsupportedUserLocation catch (_) {
      throw UnsupportedUserLocationException();
    } on GenerativeAIException catch (e) {
      if (e.message.startsWith('Candidate was blocked due to safety')) {
        throw SafetyException();
      }

      rethrow;
    } catch (e) {
      print(e);
      rethrow;
    }
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
        .contains('https://generativelanguage.googleapis.com/v1beta/models')) {
      return _client.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );
    }

    final response = await _client.post(
      Uri.parse(url.toString().replaceAll(
          'https://generativelanguage.googleapis.com/v1beta/models',
          _projectUrl)),
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
