import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translate_options/translate_options.dart';
import 'package:arb_translate/src/translation_delegates/translate_exception.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
          model: model.key,
          apiKey: apiKey,
          safetySettings: disableSafety ? _disabledSafetySettings : [],
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
