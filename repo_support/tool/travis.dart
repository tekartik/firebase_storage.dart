import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'storage',
    'storage_browser',
    'storage_fs',
    // 'storage_node',
    'storage_test',
    'storage_rest',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
  
  dart pub get
  dart run tool/travis.dart
  
''');
    shell = shell.popd();
  }
}
