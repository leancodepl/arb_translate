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
          const argResultsCustomModelProviderUrl =
              'http://argResultsCustomModelProviderBaseUrl';
          const argResultsModel = Model.gemini10Pro;
          const argResultsCustomModel = 'argResultsCustomModel';
          const argResultsApiKey = 'argResultsApiKey';
          const argResultsVertexAiProjectUrl =
              'https://argResultsVertexAiProjectUrl/models';
          const argResultsDisableSafety = true;
          const argResultsContext = 'argResultsContext';
          const argResultsExcludeLocales = ['pl'];
          const argResultsBatchSize = 4096;
          const argResultsArbDir = 'argResultsArbDir';
          const argResultsTemplateArbFile = 'argResultsTemplateArbFile';
          const argResultsUseEscaping = true;
          const argResultsRelaxSyntax = true;

          final argResults = TranslateArgResults(
            help: false,
            modelProvider: argResultsModelProvider,
            customModelProviderBaseUrl: argResultsCustomModelProviderUrl,
            model: argResultsModel,
            customModel: argResultsCustomModel,
            apiKey: argResultsApiKey,
            vertexAiProjectUrl: argResultsVertexAiProjectUrl,
            disableSafety: argResultsDisableSafety,
            context: argResultsContext,
            excludeLocales: argResultsExcludeLocales,
            batchSize: argResultsBatchSize,
            arbDir: argResultsArbDir,
            templateArbFile: argResultsTemplateArbFile,
            useEscaping: argResultsUseEscaping,
            relaxSyntax: argResultsRelaxSyntax,
          );
          final yamlResults = TranslateYamlResults(
            modelProvider: ModelProvider.gemini,
            customModelProviderBaseUrl:
                'http://yamlResultsCustomModelProviderBaseUrl',
            model: Model.gpt35Turbo,
            customModel: 'yamlResultsCustomModel',
            apiKey: 'yamlResultsApiKey',
            vertexAiProjectUrl: 'https://yamlResultsVertexAiProjectUrl/models',
            disableSafety: !argResultsDisableSafety,
            context: 'yamlResultsContext',
            excludeLocales: ['en'],
            batchSize: 2048,
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
                  (options) => options.customModelProviderBaseUrl,
                  'customModelProviderBaseUrl',
                  Uri.parse(argResultsCustomModelProviderUrl),
                )
                .having(
                  (options) => options.model,
                  'model',
                  argResultsModel,
                )
                .having(
                  (options) => options.customModel,
                  'customModel',
                  argResultsCustomModel,
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
                  (options) => options.batchSize,
                  'batchSize',
                  argResultsBatchSize,
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
