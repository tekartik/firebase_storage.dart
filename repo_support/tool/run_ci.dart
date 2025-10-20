import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'storage',
    'storage_browser',
    'storage_fs',
    'storage_test',
    'storage_sim',
  ]) {
    await packageRunCi(join('..', dir));
  }
  await packageRunCi('.');
}
