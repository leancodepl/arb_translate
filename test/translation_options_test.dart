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
          const arbResultsModel = Model.gemini10Pro;
          const argResultsApiKey = 'argResultsApiKey';
          const argResultsVertexAiProjectUrl =
              'https://argResultsVertexAiProjectUrl/models';
          const argResultsDisableSafety = true;
          const argResultsContext = 'argResultsContext';
          const argResultsExcludeLocales = ['pl'];
          const argResultsArbDir = 'argResultsArbDir';
          const argResultsTemplateArbFile = 'argResultsTemplateArbFile';
          const argResultsUseEscaping = true;
          const argResultsRelaxSyntax = true;

          final argResults = TranslateArgResults(
            help: false,
            modelProvider: argResultsModelProvider,
            model: arbResultsModel,
            apiKey: argResultsApiKey,
            vertexAiProjectUrl: argResultsVertexAiProjectUrl,
            disableSafety: argResultsDisableSafety,
            context: argResultsContext,
            excludeLocales: argResultsExcludeLocales,
            arbDir: argResultsArbDir,
            templateArbFile: argResultsTemplateArbFile,
            useEscaping: argResultsUseEscaping,
            relaxSyntax: argResultsRelaxSyntax,
          );
          final yamlResults = TranslateYamlResults(
            modelProvider: ModelProvider.gemini,
            model: Model.gpt35Turbo,
            apiKey: 'yamlResultsApiKey',
            vertexAiProjectUrl: 'https://yamlResultsVertexAiProjectUrl/models',
            disableSafety: !argResultsDisableSafety,
            context: 'yamlResultsContext',
            excludeLocales: ['en'],
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
                  (options) => options.model,
                  'model',
                  arbResultsModel,
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
                  (options) => options.disableSafety,
                  'disableSafety',
                  argResultsDisableSafety,
                )
                .having(
                  (options) => options.context,
                  'context',
                  argResultsContext,
                )
                .having(
                  (options) => options.excludeLocales,
                  'excludeLocales',
                  argResultsExcludeLocales,
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
