@TestOn('vm')
library tekartik_firebase_sembast.storage_io_test;

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();

  group('storage_fs', () {
    run(firebase: firebase, storageService: storageServiceMemory);
  });
}
