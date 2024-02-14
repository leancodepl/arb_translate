# arb_translate

[![arb_translate on pub.dev][pub_badge]][pub_link]

A command-line tool for automatically generating missing translations to ARB files
using Google Gemini LLM by [LeanCode](https://leancode.co)

## Installation

```console
$ dart pub global activate arb_translate
```

## Configuration

`arb_translate` has been designed to seamlessly integrate with Flutter apps
using `flutter_localizations` for code generation from ARB files. Thanks to this
integration, the setup process for arb_translate can be completed in just a few
steps:

### With l10n.yaml configuration file

1. Generate your Gemini API token by following
   https://ai.google.dev/tutorials/setup
2. Save your API token in the environment variable `ARB_TRANSLATE_API_KEY` or
   add `arb-translate-api-key: {your-api-key}` to `l10n.yaml` in your project
3. (Optional) Add context of your application
   `arb-translate-context: {your-app-context}` eg. "sporting goods store app"

All other required parameters match `flutter_localizations` parameters and will
be read from `l10n.yaml` file. You can override them using command arguments if
necessary. See `arb_translate --help` for more information.

### Without l10n.yaml configuration file

1. Generate your Gemini API token by following
   https://ai.google.dev/tutorials/setup
2. Save your API token in the environment variable `ARB_TRANSLATE_API_KEY` or
   specify as command argument `--api-key {your-api-key}`
3. Specify other option as command arguments:
   1. `--arb-dir` The directory where the template and translated ARB files are
      located
   2. `--template-arb-file` The template ARB file that will be used as the basis
      for translation
   3. (Optional) Add context of your application `--context {your-app-context}`
      eg. "sporting goods store app"

See `arb_translate --help` for more information.

### Configuration in regions where Gemini API is unavailable

Gemini API is not available in all regions such as EU. You can strill use
`arb_translate` but you need to access Gemini via Vertex AI service from Google
Cloud Platform. Because of that configuration is a bit longer:

1. Create your GCP project and enable Vertex AI by following
   https://cloud.google.com/vertex-ai/docs/generative-ai/start/quickstarts/api-quickstart
2. Generate your API token using gcloud CLI
   ```console
   $ gcloud auth print-access-token
   ```
3. Save your API token in the environment variable `ARB_TRANSLATE_API_KEY` or
   add `arb-translate-api-key: {your-api-key}` to `l10n.yaml` or specify as
   command argument `--api-key {your-api-key}`
4. Add `arb-translate-vertex-ai-project-url: {your-project-url}` to `l10n.yaml`
   or specify as command argument `--vertex-ai-project-url {your-project-url}`.
   Project url should look like this `https://{region}-aiplatform.googleapis.com/v1/projects/{your-project-id}/locations/{region}/publishers/google/models`
5. Add `arb-translate-model-provider: vertex-ai` to `l10n.yaml` or specify as
   command argument `--model-provider: vertex-ai`

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
If you want to know how we made this tool and what challenges we had, [read the story](https://leancode.co/blog/flutter-app-localization-with-ai?utm_source=readme&utm_medium=arb_translate_package).

##

<p align="center">
   <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://leancodepublic.blob.core.windows.net/public/dark-transparent-wide.png">
      <source media="(prefers-color-scheme: light)" srcset="https://leancodepublic.blob.core.windows.net/public/light-transparent-wide.png">
      <img alt="LeanCode" src="https://leancodepublic.blob.core.windows.net/public/wide.png" width="300"/>
   </picture>
   <p align="center">
   Built with ☕️ by <a href="https://leancode.co">LeanCode</a>
   </p>
</p>
