# arb_translate

[![arb_translate on pub.dev][pub_badge]][pub_link]

A command-line tool for automatically generating missing translations to ARB
files using Google Gemini or OpenAI ChatGPT by
[LeanCode](https://leancode.co/?utm_source=readme&utm_medium=arb_translate_package)

## Installation

```console
$ dart pub global activate arb_translate
```

## Configuration

`arb_translate` has been designed to seamlessly integrate with Flutter apps
using `flutter_localizations` for code generation from ARB files. Thanks to this
integration, the setup process for arb_translate can be completed in just a few
steps:

1. Generate your API key. You can create your Gemini key
   [here](https://makersuite.google.com/app/apikey) or your OpenAI key
   [here](https://platform.openai.com/api-keys)

2. Save your API token in the environment variable `ARB_TRANSLATE_API_KEY` or
   add `arb-translate-api-key: {your-api-key}` to `l10n.yaml` in your project.

3. If you are using ChatGPT select OpenAI as model provider. To do it add
   `arb-translate-model-provider: open-ai` to `l10n.yaml` or use command
   argument `--model-provider: open-ai`

4. (Optional) Select model used for translation. To do it add
   `arb-translate-model` to `l10n.yaml` or use command argument `--model`. The available options are `[gemini-1.0-pro (default for Gemini), gemini-1.5-pro, gemini-1.5-flash, gpt-3.5-turbo (default for OpenAI), gpt-4, gpt-4-turbo, gpt-4o]`

5. (Optional) Add context of your application
   `arb-translate-context: {your-app-context}` eg. "sporting goods store app"

All other required parameters match `flutter_localizations` parameters and will
be read from `l10n.yaml` file. You can override them using command arguments if
necessary. See `arb_translate --help` for more information.

### Configuration without l10n.yaml
If you project doesn't include `l10n.yaml` configuration you have to provide
configuration using environment variables and command arguments. You also have
to provide:

1. `--arb-dir` The directory where the template and translated ARB files are
   located

2. `--template-arb-file` The template ARB file that will be used as the basis
   for translation

See `arb_translate --help` for more information.

### Vertex AI configuration
You can use `arb_translate` with Vertex AI service from Google Cloud Platform
but configuration is a bit longer:

1. Create your GCP project and enable Vertex AI by following
   https://cloud.google.com/vertex-ai/docs/generative-ai/start/quickstarts/api-quickstart
2. Generate your API token using gcloud CLI
   ```console
   $ gcloud auth print-access-token
   ```
3. Save your API token in the environment variable `ARB_TRANSLATE_API_KEY` or
   add `arb-translate-api-key: {your-api-key}` to `l10n.yaml` or specify as
   command argument `--api-key {your-api-key}`
4. Add `arb-translate-model-provider: vertex-ai` to `l10n.yaml` or specify as
   command argument `--model-provider: vertex-ai`
5. Add `arb-translate-vertex-ai-project-url: {your-project-url}` to `l10n.yaml`
   or specify as command argument `--vertex-ai-project-url {your-project-url}`.
   Project url should look like this
   `https://{region}-aiplatform.googleapis.com/v1/projects/{your-project-id}/locations/{region}/publishers/google/models`


### Custom model configuration
You can use `arb_translate` with any model with an OpenAI-compatible API. To configure a custom model:

1. Add `arb-translate-model-provider: custom` to `l10n.yaml` or specify as
   command argument `--model-provider: custom`
2. Add `arb-translate-custom-model: {your-model-name}` to `l10n.yaml` or specify
   as command argument `custom-model: {your-model-name}`
3. Add `arb-translate-custom-model-provider-base-url: {your-model-url}` to 
   `l10n.yaml` or specify as command argument: `--custom-model-provider-base-url: {your-model-url}`
4. (Optional) Set target batch size appropriately to model token count limits by
   adding `arb-translate-batch-size: {size}` to your `l10n.yaml` or specify as
   command argument `batch-size: {size}`. Batch size is the number of characters
   of ARB messages in a single batch and does not include the prompt or app
   context.

## Usage
To generate translations, simply call arb_translate. All messages included in
the template ARB file but missing from other files will be translated. To add a
new locale, simply add an empty ARB file.

```console
$ arb_translate
```

Or without `l10n.yaml` file

```console
$ arb_translate --arb-dir...
```

[pub_badge]: https://img.shields.io/pub/v/arb_translate.svg
[pub_link]: https://pub.dartlang.org/packages/arb_translate

## Read more
If you want to know how we made this tool and what challenges we had,
[read the story](https://leancode.co/blog/flutter-app-localization-with-ai?utm_source=readme&utm_medium=arb_translate_package).

##

<p align="center">
   <a href="https://leancode.co/?utm_source=readme&utm_medium=arb_translate_package">
      <img alt="LeanCode" src="https://leancodepublic.blob.core.windows.net/public/wide.png" width="300"/>
   </a>
   <p align="center">
   Built with ☕️ by <a href="https://leancode.co/?utm_source=readme&utm_medium=arb_translate_package">LeanCode</a>
   </p>
</p>
