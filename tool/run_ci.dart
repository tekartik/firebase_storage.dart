//@dart=2.9

import 'package:dev_test/package.dart';

Future<void> main() async {
  for (var dir in [
    'storage',
    'storage_browser',
    'storage_fs',
    // 'storage_node',
    'storage_test',
    'storage_rest',
  ]) {
    await packageRunCi(dir);
  }
}
