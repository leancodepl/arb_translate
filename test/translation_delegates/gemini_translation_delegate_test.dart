import 'dart:io';

import 'package:arb_translate/src/translate_options/translate_options.dart';
import 'package:arb_translate/src/translation_delegates/gemini_translation_delegate.dart';
import 'package:test/test.dart';

import 'util.dart';

void main() {
  group(
    'GeminiTranslationDelegate',
    () {
      group(
        'using Gemini API',
        () {
          setUpAll(
            () {
              if (Platform
                      .environment['ARB_TRANSLATE_GEMINI_API_KEY']?.isEmpty ??
                  true) {
                throw Exception(
                    'Missing ARB_TRANSLATE_GEMINI_API_KEY environment variable');
              }
            },
          );

          GeminiTranslationDelegate createDelegate(Model model) {
            return GeminiTranslationDelegate(
              model: model,
              apiKey: Platform.environment['ARB_TRANSLATE_GEMINI_API_KEY']!,
              batchSize: 4096,
              context: context,
              disableSafety: false,
              useEscaping: false,
              relaxSyntax: false,
            );
          }

          for (final model in Model.geminiModels) {
            test(
              'returns a result from ${model.name}',
              () async {
                await tryTranslateWithDelegate(createDelegate(model));
              },
            );
          }
        },
      );

      group(
        'using Vertex AI API',
        () {
          setUpAll(
            () {
              if (Platform.environment['ARB_TRANSLATE_VERTEX_AI_API_KEY']
                      ?.isEmpty ??
                  true) {
                throw Exception(
                    'Missing ARB_TRANSLATE_VERTEX_AI_API_KEY environment variable');
              }

              if (Platform.environment['ARB_TRANSLATE_VERTEX_AI_PROJECT_URL']
                      ?.isEmpty ??
                  true) {
                throw Exception(
                    'Missing ARB_TRANSLATE_VERTEX_AI_PROJECT_URL environment variable');
              }
            },
          );

          GeminiTranslationDelegate createDelegate(Model model) {
            return GeminiTranslationDelegate.vertexAi(
              model: model,
              apiKey: Platform.environment['ARB_TRANSLATE_VERTEX_AI_API_KEY']!,
              projectUrl: Uri.parse(
                  Platform.environment['ARB_TRANSLATE_VERTEX_AI_PROJECT_URL']!),
              batchSize: 4096,
              context: context,
              disableSafety: false,
              useEscaping: false,
              relaxSyntax: false,
            );
          }

          for (final model in Model.geminiModels) {
            test(
              'returns a result from ${model.name}',
              () async {
                await tryTranslateWithDelegate(createDelegate(model));
              },
            );
          }
        },
      );
    },
  );
}
