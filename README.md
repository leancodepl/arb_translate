# arb_translate

[![arb_translate on pub.dev][pub_badge]][pub_link]

Command-line tool automatically adding missing message translations to ARB files
using Google Gemini LLM.

## Installation

```console
$ dart pub global activate arb_translate
```

## Configuration

`arb_translate` is designed to seamlessly integrate with
`flutter_localizations`. If you project includes `l10n.yaml` configuration file
`arb_translate` will use it and only configuration required is providing API key
for Gemini.

### With l10n.yaml configuration file

1. Provide Gemini API key. You can do this using `--gemini-api-key` command
   argument, `gemini-api-key:` parameter in `l10n.yaml` file, or using
   `GEMINI_API_KEY` environment variable.

All other parameters match `flutter_localizations` parameters and will be read
from `l10n.yaml` file. You can override them using command arguments if
necessary. See `arb_translate --help` for more information.

### Without l10n.yaml configuration file

1. Provide Gemini API key. You can do this using `--gemini-api-key` command
   argument, or using `GEMINI_API_KEY` environment variable.
2. Specify other option as command arguments:
   1. `--arb-dir` The directory where the template and translated arb files are
      located
   2. `--template-arb-file` The template arb file that will be used as the basis for translation
   3. `--use-escaping` Whether or not to use escaping for messages.
   4. `--relax-syntax` When specified, the syntax will be relaxed

See `arb_translate --help` for more information.

## Usage
To generate translations simply call `arb_translate`. All messages included in template ARB file but missing from other files will be translated. To add new locale simply add empty arb file it.

```console
$ arb_translate
```

[pub_badge]: https://img.shields.io/pub/v/arb_translate.svg
[pub_link]: https://pub.dartlang.org/packages/arb_translate
