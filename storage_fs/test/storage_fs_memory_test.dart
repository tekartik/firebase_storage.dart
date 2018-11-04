@TestOn('vm')
library tekartik_firebase_sembast.storage_io_test;

import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart';

import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();

  group('storage_fs', () {
    run(firebase: firebase, storageService: storageServiceMemory);

    var app = firebase.initializeApp();
    var storage = storageServiceMemory.storage(app);
    setUpAll(() {});
    tearDownAll(() {
      return app.delete();
    });

    test('bucket_no_name', () async {
      var bucketIo = storage.bucket() as BucketIo;
      expect(
          bucketIo.localPath,
          join(".dart_tool", "tekartik_firebase_local", "_default",
              "storage._default"));
    });
    test('default_bucket_local_path', () async {
      var old = firebaseSembastIoDefaultBucketLocalPath;
      try {
        firebaseSembastIoDefaultBucketLocalPath = "some_dir";
        var bucketIo = storage.bucket() as BucketIo;
        expect(bucketIo.localPath, "some_dir");
      } finally {
        // restore
        firebaseSembastIoDefaultBucketLocalPath = old;
      }
    });

    test('create_no_tree', () async {
      var fileIo = storage.bucket("test").file("test") as FileIo;

      // delete a top folder to force creating the tree again
      try {
        await io.Directory(fileIo.bucket.localPath).delete(recursive: true);
      } catch (_) {}
      expect(await fileIo.exists(), isFalse);
      await fileIo.save("test");
      expect(await fileIo.exists(), isTrue);
    });
  });
}
