import 'package:arb_translate/arb_translate.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  group(
    'TranslateOptions',
    () {
      test(
        'resolve returns options with values from argResults over yamlResults',
        () {
          const argResultsModelProvider = ModelProvider.vertexAi;
          const argResultsApiKey = 'argResultsApiKey';
          const argResultsVertexAiProjectUrl =
              'https://argResultsVertexAiProjectUrl/models';
          const argResultsContext = 'argResultsContext';
          const argResultsArbDir = 'argResultsArbDir';
          const argResultsTemplateArbFile = 'argResultsTemplateArbFile';
          const argResultsUseEscaping = true;
          const argResultsRelaxSyntax = true;

          final argResults = TranslateArgResults(
            help: false,
            modelProvider: argResultsModelProvider,
            apiKey: argResultsApiKey,
            vertexAiProjectUrl: argResultsVertexAiProjectUrl,
            context: argResultsContext,
            arbDir: argResultsArbDir,
            templateArbFile: argResultsTemplateArbFile,
            useEscaping: argResultsUseEscaping,
            relaxSyntax: argResultsRelaxSyntax,
          );
          final yamlResults = TranslateYamlResults(
            modelProvider: ModelProvider.gemini,
            apiKey: 'yamlResultsApiKey',
            vertexAiProjectUrl: 'htts://yamlResultsVertexAiProjectUrl/models',
            context: 'yamlResultsContext',
            arbDir: 'yamlResultsArbDir',
            templateArbFile: 'yamlResultsTemplateArbFile',
            useEscaping: !argResultsUseEscaping,
            relaxSyntax: !argResultsRelaxSyntax,
          );

          final translateOptions = TranslateOptions.resolve(
            MemoryFileSystem(),
            argResults,
            yamlResults,
          );

          expect(
            translateOptions,
            isA<TranslateOptions>()
                .having(
                  (options) => options.modelProvider,
                  'modelProvider',
                  argResultsModelProvider,
                )
                .having(
                  (options) => options.apiKey,
                  'apiKey',
                  argResultsApiKey,
                )
                .having(
                  (options) => options.vertexAiProjectUrl,
                  'vertexAiProjectUrl',
                  Uri.parse(argResultsVertexAiProjectUrl),
                )
                .having(
                  (options) => options.context,
                  'context',
                  argResultsContext,
                )
                .having(
                  (options) => options.arbDir,
                  'arbDir',
                  argResultsArbDir,
                )
                .having(
                  (options) => options.templateArbFile,
                  'templateArbFile',
                  argResultsTemplateArbFile,
                )
                .having(
                  (options) => options.useEscaping,
                  'useEscaping',
                  argResultsUseEscaping,
                )
                .having(
                  (options) => options.relaxSyntax,
                  'relaxSyntax',
                  argResultsRelaxSyntax,
                ),
          );
        },
      );
    },
  );
}
