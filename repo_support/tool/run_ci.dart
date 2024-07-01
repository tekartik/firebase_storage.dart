import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'storage',
    'storage_browser',
    'storage_fs',
    'storage_test',
  ]) {
    await packageRunCi(join('..', dir));
  }
  await packageRunCi('.');
}
