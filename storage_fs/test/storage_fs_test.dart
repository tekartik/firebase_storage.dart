library tekartik_firebase_sembast.storage_fs_memory_test;

import 'package:fs_shim/fs_memory.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:test/test.dart';

void main() {
  group('storage_fs', () {
    test('new', () async {
      var app = newFirebaseAppLocal();
      var fs = newFileSystemMemory();
      var storageService =
          newStorageServiceFs(fileSystem: fs, basePath: 'base');
      var storage = storageService.storage(app);
      var file = storage.bucket().file('test');
      await file.writeAsString('text');
      var fsFile = fs.file('/base/_default/data/test');
      expect(await fsFile.readAsString(), 'text');

      file = storage.bucket().file('/test');
      await file.writeAsString('text2');
      fsFile = fs.file('/base/_default/data/test');
      expect(await fsFile.readAsString(), 'text2');
    });
    test('bucket localPath with basePath', () {
      var app = newFirebaseAppLocal();
      var fs = newFileSystemMemory();
      var storageService =
          newStorageServiceFs(fileSystem: fs, basePath: 'base');
      var storage = storageService.storage(app);
      var bucket = storage.bucket() as BucketFs;
      expect(bucket.localPath, 'base/_default');
      var file = bucket.file('test');
      expect(file.fsFile.path, 'base/_default/data/test');
      file = bucket.file('/test');
      expect(file.fsFile.path, 'base/_default/data/test');

      app.delete();
    });
    test('bucket localPath without basePath', () {
      var app = newFirebaseAppLocal();
      var fs = newFileSystemMemory();
      var storageService = newStorageServiceFs(fileSystem: fs);
      var storage = storageService.storage(app);
      var bucket = storage.bucket() as BucketFs;
      expect(bucket.localPath,
          '.dart_tool/tekartik_firebase_local/_default/storage/_default');
      var file = bucket.file('test');
      expect(file.fsFile.path, url.join(bucket.localPath!, 'data/test'));
      file = bucket.file('/test');
      expect(file.fsFile.path, url.join(bucket.localPath!, 'data/test'));

      app.delete();
    });
  });
}
