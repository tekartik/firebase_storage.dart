@TestOn('vm')
library tekartik_firebase_sembast.storage_fs_memory_test;

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();

  group('storage_fs', () {
    run(
        firebase: firebase,
        storageService: storageServiceMemory,
        storageOptions: TestStorageOptions(bucket: 'my_bucket'));

    test('new', () async {
      var app = firebase.initializeApp();

      var storageService1 = newStorageServiceMemory();
      var storage1 = storageService1.storage(app);
      var file1 = storage1.bucket().file('test');
      await file1.writeAsString('test');
      expect(await file1.readAsString(), 'test');

      // another one
      var storageService2 = newStorageServiceMemory();
      expect(storageService2, isNot(storageService1));
      var storage2 = storageService2.storage(app);
      expect(storage2, isNot(storage1));
      var file2 = storage2.bucket().file('test');
      try {
        await file2.readAsString();
        fail('should fail');
      } catch (e) {
        expect(e, isNot(const TypeMatcher<TestFailure>()));
      }
    });
  });
}
