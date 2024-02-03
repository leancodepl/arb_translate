import 'package:arb_gpt_translator/src/commands/translate_command.dart';
import 'package:args/command_runner.dart';

Future<void> main(List<String> arguments) {
  final runner = CommandRunner<void>('translator', '')
    ..addCommand(TranslateCommand());

  return runner.run(arguments);
}
