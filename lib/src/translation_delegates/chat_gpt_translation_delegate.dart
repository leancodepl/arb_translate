import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:arb_translate/src/translate_options/translate_options.dart';
import 'package:arb_translate/src/translation_delegates/translate_exception.dart';
import 'package:arb_translate/src/translation_delegates/translation_delegate.dart';
import 'package:dart_openai/dart_openai.dart';

class ChatGptTranslationDelegate extends TranslationDelegate {
  ChatGptTranslationDelegate({
    required Model model,
    required String apiKey,
    required super.batchSize,
    required super.context,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = model.key {
    OpenAI.apiKey = apiKey;
    OpenAI.requestsTimeOut = Duration(minutes: 2);
  }

  ChatGptTranslationDelegate.custom({
    required String model,
    required String apiKey,
    required Uri baseUrl,
    required super.batchSize,
    required super.context,
    required super.useEscaping,
    required super.relaxSyntax,
  }) : _model = model {
    OpenAI.apiKey = apiKey;
    OpenAI.requestsTimeOut = Duration(minutes: 60);
    OpenAI.baseUrl = baseUrl.toString();
  }

  final String _model;

  @override
  int get maxRetryCount => 5;
  @override
  int get maxParallelQueries => 5;
  @override
  Duration get queryBackoff => Duration(seconds: 5);

  @override
  Future<String> getModelResponse(
    Map<String, Object?> resources,
    LocaleInfo locale,
  ) async {
    final encodedResources = JsonEncoder.withIndent('  ').convert(resources);

    final prompt = [
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            'Translate ARB messages for ${context ?? 'app'} to locale '
            '"$locale". Add other ICU plural forms according to CLDR rules if '
            'necessary. Return only raw JSON.\n\n'
            '$encodedResources',
          )
        ],
        role: OpenAIChatMessageRole.user,
      ),
    ];

    try {
      final response = (await OpenAI.instance.chat.create(
        model: _model,
        responseFormat:
            _model != Model.gpt4.key ? {"type": "json_object"} : null,
        messages: prompt,
      ))
          .choices
          .first
          .message
          .content!
          .first
          .text;

      if (response == null) {
        throw NoResponseException();
      }

      return response;
    } on RequestFailedException catch (e) {
      if (e.statusCode == 401) {
        throw InvalidApiKeyException();
      } else if (e.statusCode == 429) {
        throw QuotaExceededException();
      }
      rethrow;
    }
  }
}
