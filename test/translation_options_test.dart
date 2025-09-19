import 'package:arb_translate/arb_translate.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  const argResultsApiKey = 'argResultsApiKey';
  const argResultsDisableSafety = true;
  const argResultsContext = 'argResultsContext';
  const argResultsExcludeLocales = ['pl'];
  const argResultsBatchSize = 4096;
  const argResultsArbDir = 'argResultsArbDir';
  const argResultsTemplateArbFile = 'argResultsTemplateArbFile';
  const argResultsUseEscaping = true;
  const argResultsRelaxSyntax = true;
  group(
    'TranslateOptions',
    () {
      test(
        'resolve returns options with values from argResults over yamlResults',
        () {
          const argResultsModel = Model.gemini25Flash;
          const argResultsCustomModelProviderUrl =
              'http://argResultsCustomModelProviderBaseUrl';
          const argResultsCustomModel = 'argResultsCustomModel';

          final argResults = TranslateArgResults(
            help: false,
            customModelProviderBaseUrl: argResultsCustomModelProviderUrl,
            model: argResultsModel,
            customModel: argResultsCustomModel,
            apiKey: argResultsApiKey,
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
            customModelProviderBaseUrl:
                'http://yamlResultsCustomModelProviderBaseUrl',
            model: Model.gpt5Mini,
            customModel: 'yamlResultsCustomModel',
            apiKey: 'yamlResultsApiKey',
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
  group(
    'modelProvider resolving',
    () {
      test('resolves gemini provider', () {
        const argResultsModel = Model.gemini25Flash;
        final argResults = TranslateArgResults(
          help: false,
          customModelProviderBaseUrl: null,
          model: argResultsModel,
          customModel: null,
          apiKey: argResultsApiKey,
          disableSafety: argResultsDisableSafety,
          context: argResultsContext,
          excludeLocales: argResultsExcludeLocales,
          batchSize: argResultsBatchSize,
          arbDir: argResultsArbDir,
          templateArbFile: argResultsTemplateArbFile,
          useEscaping: argResultsUseEscaping,
          relaxSyntax: argResultsRelaxSyntax,
        );
        final yamlResults = TranslateYamlResults.empty();
        final translateOptions = TranslateOptions.resolve(
          MemoryFileSystem(),
          argResults,
          yamlResults,
        );
        expect(
            translateOptions,
            isA<TranslateOptions>().having((options) => options.modelProvider,
                'modelProvider', ModelProvider.gemini));
      });
      test('resolves openAI provider', () {
        const argResultsModel = Model.gpt5Mini;
        final argResults = TranslateArgResults(
          help: false,
          customModelProviderBaseUrl: null,
          model: argResultsModel,
          customModel: null,
          apiKey: argResultsApiKey,
          disableSafety: argResultsDisableSafety,
          context: argResultsContext,
          excludeLocales: argResultsExcludeLocales,
          batchSize: argResultsBatchSize,
          arbDir: argResultsArbDir,
          templateArbFile: argResultsTemplateArbFile,
          useEscaping: argResultsUseEscaping,
          relaxSyntax: argResultsRelaxSyntax,
        );
        final yamlResults = TranslateYamlResults.empty();
        final translateOptions = TranslateOptions.resolve(
          MemoryFileSystem(),
          argResults,
          yamlResults,
        );
        expect(
            translateOptions,
            isA<TranslateOptions>().having((options) => options.modelProvider,
                'modelProvider', ModelProvider.openAi));
      });
      test(
          'resolves customOpenAiCompatible provider with custom model taking precedence',
          () {
        const argResultsModel = Model.gemini25Flash;
        const argResultsCustomModelProviderUrl =
            'http://argResultsCustomModelProviderBaseUrl';
        const argResultsCustomModel = 'argResultsCustomModel';
        final argResults = TranslateArgResults(
          help: false,
          customModelProviderBaseUrl: argResultsCustomModelProviderUrl,
          model: argResultsModel,
          customModel: argResultsCustomModel,
          apiKey: argResultsApiKey,
          disableSafety: argResultsDisableSafety,
          context: argResultsContext,
          excludeLocales: argResultsExcludeLocales,
          batchSize: argResultsBatchSize,
          arbDir: argResultsArbDir,
          templateArbFile: argResultsTemplateArbFile,
          useEscaping: argResultsUseEscaping,
          relaxSyntax: argResultsRelaxSyntax,
        );
        final yamlResults = TranslateYamlResults.empty();
        final translateOptions = TranslateOptions.resolve(
          MemoryFileSystem(),
          argResults,
          yamlResults,
        );
        expect(
          translateOptions,
          isA<TranslateOptions>()
              .having((o) => o.modelProvider, 'modelProvider',
                  ModelProvider.customOpenAiCompatible)
              .having(
                  (o) => o.customModel, 'customModel', argResultsCustomModel),
        );
      });
    },
  );
}
