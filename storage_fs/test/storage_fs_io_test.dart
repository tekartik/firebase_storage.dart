@TestOn('vm')
library tekartik_firebase_sembast.storage_io_test;

import 'package:path/path.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs_io.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();

  group('storage_fs_io', () {
    run(
        firebase: firebase,
        storageService: storageServiceIo,
        storageOptions: TestStorageOptions(bucket: 'my_bucket'));

    var fileSystem = (storageServiceIo as StorageServiceFs).fileSystem;
    var app = firebase.initializeApp();
    var storage = storageServiceIo.storage(app);
    setUpAll(() {});
    tearDownAll(() {
      return app.delete();
    });

    test('bucket_no_name', () async {
      var bucketIo = storage.bucket() as BucketFs;
      expect(
          bucketIo.localPath,
          join('.dart_tool', 'tekartik_firebase_local', '_default', 'storage',
              '_default'));
    });
    test('create_no_tree', () async {
      var bucket = storage.bucket('test');
      var fileFs = bucket.file('test') as FileFs;

      // delete a top folder to force creating the tree again
      try {
        await fileSystem
            .directory(fileFs.bucket.localPath)
            .delete(recursive: true);
      } catch (_) {}
      expect(await bucket.exists(), isFalse);
      expect(await fileFs.exists(), isFalse);
      await fileFs.save('test');
      expect(await fileFs.exists(), isTrue);
      expect(await bucket.exists(), isTrue);
    });

    group('basePath', () {
      var storageService = createStorageServiceIo(
          basePath: join('.dart_tool', 'firebase_storage_fs', 'base_path'));
      test('override', () async {
        var storage = storageService.storage(app);

        var bucketIo = storage.bucket() as BucketFs;
        expect(bucketIo.localPath,
            join('.dart_tool', 'firebase_storage_fs', 'base_path', '_default'));
      });
    });
  });
}
