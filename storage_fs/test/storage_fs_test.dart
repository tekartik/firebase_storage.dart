library tekartik_firebase_sembast.storage_fs_memory_test;

import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:test/test.dart';

void main() {
  group('storage_fs', () {
    test('new', () async {
      var app = newFirebaseAppLocal();
      var fs = newFileSystemMemory();
      var storageService = newStorageServiceFs(fs, basePath: 'base');
      var storage = storageService.storage(app);
      var file = storage.bucket().file('test');
      await file.writeAsString('text');
      var fsFile = fs.file('/base/_default/data/test');
      expect(await fsFile.readAsString(), 'text');
    });
  });
}
