import 'dart:convert';

import 'package:arb_translate/src/flutter_tools/localizations_utils.dart';
import 'package:file/file.dart';
import 'package:intl/locale.dart';

int sortFilesByPath(File a, File b) {
  return a.path.compareTo(b.path);
}

class L10nException implements Exception {
  L10nException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Represents the contents of one ARB file.
class AppResourceBundle {
  /// Assuming that the caller has verified that the file exists and is readable.
  factory AppResourceBundle(File file) {
    final Map<String, Object?> resources;
    try {
      final String content = file.readAsStringSync().trim();
      if (content.isEmpty) {
        resources = <String, Object?>{};
      } else {
        resources = json.decode(content) as Map<String, Object?>;
      }
    } on FormatException catch (e) {
      throw L10nException(
        'The arb file ${file.path} has the following formatting issue: \n'
        '$e',
      );
    }

    String? localeString = resources['@@locale'] as String?;

    // Look for the first instance of an ISO 639-1 language code, matching exactly.
    final String fileName =
        file.fileSystem.path.basenameWithoutExtension(file.path);

    for (int index = 0; index < fileName.length; index += 1) {
      // If an underscore was found, check if locale string follows.
      if (fileName[index] == '_') {
        // If Locale.tryParse fails, it returns null.
        final Locale? parserResult =
            Locale.tryParse(fileName.substring(index + 1));
        // If the parserResult is not an actual locale identifier, end the loop.
        if (parserResult != null &&
            _iso639Languages.contains(parserResult.languageCode)) {
          // The parsed result uses dashes ('-'), but we want underscores ('_').
          final String parserLocaleString =
              parserResult.toString().replaceAll('-', '_');

          if (localeString == null) {
            // If @@locale was not defined, use the filename locale suffix.
            localeString = parserLocaleString;
          } else {
            // If the localeString was defined in @@locale and in the filename, verify to
            // see if the parsed locale matches, throw an error if it does not. This
            // prevents developers from confusing issues when both @@locale and
            // "_{locale}" is specified in the filename.
            if (localeString != parserLocaleString) {
              throw L10nException(
                  'The locale specified in @@locale and the arb filename do not match. \n'
                  'Please make sure that they match, since this prevents any confusion \n'
                  'with which locale to use. Otherwise, specify the locale in either the \n'
                  'filename of the @@locale key only.\n'
                  'Current @@locale value: $localeString\n'
                  'Current filename extension: $parserLocaleString');
            }
          }
          break;
        }
      }
    }

    if (localeString == null) {
      throw L10nException(
          "The following .arb file's locale could not be determined: \n"
          '${file.path} \n'
          "Make sure that the locale is specified in the file's '@@locale' "
          'property or as part of the filename (e.g. file_en.arb)');
    }

    final Iterable<String> ids =
        resources.keys.where((String key) => !key.startsWith('@'));
    return AppResourceBundle._(
        file, LocaleInfo.fromString(localeString), resources, ids);
  }

  const AppResourceBundle._(
      this.file, this.locale, this.resources, this.resourceIds);

  final File file;
  final LocaleInfo locale;

  /// JSON representation of the contents of the ARB file.
  final Map<String, Object?> resources;
  final Iterable<String> resourceIds;

  String? translationFor(String resourceId) => resources[resourceId] as String?;

  @override
  String toString() {
    return 'AppResourceBundle($locale, ${file.path})';
  }
}

// Represents all of the ARB files in [directory] as [AppResourceBundle]s.
class AppResourceBundleCollection {
  factory AppResourceBundleCollection(Directory directory) {
    // Assuming that the caller has verified that the directory is readable.

    final RegExp filenameRE = RegExp(r'(\w+)\.arb$');
    final Map<LocaleInfo, AppResourceBundle> localeToBundle =
        <LocaleInfo, AppResourceBundle>{};
    final Map<String, List<LocaleInfo>> languageToLocales =
        <String, List<LocaleInfo>>{};
    // We require the list of files to be sorted so that
    // "languageToLocales[bundle.locale.languageCode]" is not null
    // by the time we handle locales with country codes.
    final List<File> files = directory
        .listSync()
        .whereType<File>()
        .where((File e) => filenameRE.hasMatch(e.path))
        .toList()
      ..sort(sortFilesByPath);
    for (final File file in files) {
      final AppResourceBundle bundle = AppResourceBundle(file);
      if (localeToBundle[bundle.locale] != null) {
        throw L10nException(
            "Multiple arb files with the same '${bundle.locale}' locale detected. \n"
            'Ensure that there is exactly one arb file for each locale.');
      }
      localeToBundle[bundle.locale] = bundle;
      languageToLocales[bundle.locale.languageCode] ??= <LocaleInfo>[];
      languageToLocales[bundle.locale.languageCode]!.add(bundle.locale);
    }

    languageToLocales.forEach(
        (String language, List<LocaleInfo> listOfCorrespondingLocales) {
      final List<String> localeStrings =
          listOfCorrespondingLocales.map((LocaleInfo locale) {
        return locale.toString();
      }).toList();
      if (!localeStrings.contains(language)) {
        throw L10nException(
            'Arb file for a fallback, $language, does not exist, even though \n'
            'the following locale(s) exist: $listOfCorrespondingLocales. \n'
            'When locales specify a script code or country code, a \n'
            'base locale (without the script code or country code) should \n'
            'exist as the fallback. Please create a {fileName}_$language.arb \n'
            'file.');
      }
    });

    return AppResourceBundleCollection._(
        directory, localeToBundle, languageToLocales);
  }

  const AppResourceBundleCollection._(
      this._directory, this._localeToBundle, this._languageToLocales);

  final Directory _directory;
  final Map<LocaleInfo, AppResourceBundle> _localeToBundle;
  final Map<String, List<LocaleInfo>> _languageToLocales;

  Iterable<LocaleInfo> get locales => _localeToBundle.keys;
  Iterable<AppResourceBundle> get bundles => _localeToBundle.values;
  AppResourceBundle? bundleFor(LocaleInfo locale) => _localeToBundle[locale];

  Iterable<String> get languages => _languageToLocales.keys;
  Iterable<LocaleInfo> localesForLanguage(String language) =>
      _languageToLocales[language] ?? <LocaleInfo>[];

  @override
  String toString() {
    return 'AppResourceBundleCollection(${_directory.path}, ${locales.length} locales)';
  }
}

// A set containing all the ISO630-1 languages. This list was pulled from https://datahub.io/core/language-codes.
final Set<String> _iso639Languages = <String>{
  'aa',
  'ab',
  'ae',
  'af',
  'ak',
  'am',
  'an',
  'ar',
  'as',
  'av',
  'ay',
  'az',
  'ba',
  'be',
  'bg',
  'bh',
  'bi',
  'bm',
  'bn',
  'bo',
  'br',
  'bs',
  'ca',
  'ce',
  'ch',
  'co',
  'cr',
  'cs',
  'cu',
  'cv',
  'cy',
  'da',
  'de',
  'dv',
  'dz',
  'ee',
  'el',
  'en',
  'eo',
  'es',
  'et',
  'eu',
  'fa',
  'ff',
  'fi',
  'fil',
  'fj',
  'fo',
  'fr',
  'fy',
  'ga',
  'gd',
  'gl',
  'gn',
  'gsw',
  'gu',
  'gv',
  'ha',
  'he',
  'hi',
  'ho',
  'hr',
  'ht',
  'hu',
  'hy',
  'hz',
  'ia',
  'id',
  'ie',
  'ig',
  'ii',
  'ik',
  'io',
  'is',
  'it',
  'iu',
  'ja',
  'jv',
  'ka',
  'kg',
  'ki',
  'kj',
  'kk',
  'kl',
  'km',
  'kn',
  'ko',
  'kr',
  'ks',
  'ku',
  'kv',
  'kw',
  'ky',
  'la',
  'lb',
  'lg',
  'li',
  'ln',
  'lo',
  'lt',
  'lu',
  'lv',
  'mg',
  'mh',
  'mi',
  'mk',
  'ml',
  'mn',
  'mr',
  'ms',
  'mt',
  'my',
  'na',
  'nb',
  'nd',
  'ne',
  'ng',
  'nl',
  'nn',
  'no',
  'nr',
  'nv',
  'ny',
  'oc',
  'oj',
  'om',
  'or',
  'os',
  'pa',
  'pi',
  'pl',
  'ps',
  'pt',
  'qu',
  'rm',
  'rn',
  'ro',
  'ru',
  'rw',
  'sa',
  'sc',
  'sd',
  'se',
  'sg',
  'si',
  'sk',
  'sl',
  'sm',
  'sn',
  'so',
  'sq',
  'sr',
  'ss',
  'st',
  'su',
  'sv',
  'sw',
  'ta',
  'te',
  'tg',
  'th',
  'ti',
  'tk',
  'tl',
  'tn',
  'to',
  'tr',
  'ts',
  'tt',
  'tw',
  'ty',
  'ug',
  'uk',
  'ur',
  'uz',
  've',
  'vi',
  'vo',
  'wa',
  'wo',
  'xh',
  'yi',
  'yo',
  'za',
  'zh',
  'zu',
};
