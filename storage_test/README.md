# tekartik_firebase_storage_test

The shared tests every `tekartik_firebase_storage` implementation runs
(storage_fs, storage_sim, storage_rest, storage_node, admin sdk, flutter):
write, read, list, delete and describe files through the public API only,
plus a console dev menu. Pure Dart on `package:test`: it runs wherever the
implementation under test runs (VM, browser, node).

## Getting started

Git package, not on pub.dev, used as a dev dependency of the implementation
it tests:

```yaml
dev_dependencies:
  tekartik_firebase_storage_test:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage_test
  test: '>=1.31.0'
```

The suite on the in memory storage of `tekartik_firebase_storage_fs`
(`test/storage_memory_test.dart`):

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var bucketName = 'my_bucket';

void main() {
  var storageService = newStorageServiceMemory();
  var app = FirebaseLocal().initializeApp(name: 'storage_test');

  // The bucket must exist before the suite writes in it.
  setUpAll(() async {
    await storageService.storage(app).bucket(bucketName).create();
  });
  tearDownAll(() => app.delete());

  runStorageAppTests(
    app,
    storageService: storageService,
    storageOptions: TestStorageOptions(bucket: bucketName),
  );
}
```

Run it with `dart test`.

## Entry points

* `runStorageTests(firebase:, storageService:, options:, storageOptions:)`
  creates its own app (deleted in `tearDownAll`).
* `runStorageAppTests(app, storageService:, storageOptions:)` uses an app you
  own (a sim client, a Flutter app): delete it yourself.
* `TestStorageOptions(bucket:, rootPath:, skipDefaultBucketExists:)`: the
  bucket (default: the app `storageBucket`), a path prefix for every file the
  suite touches, and whether `bucket.exists()` can be asked.

The suite checks `exists`, write/read/delete round trips, `getMetadata`
(size, md5, update date, the content type given, guessed from the name or
`application/octet-stream`, `cacheControl`) and `getFiles`: pages of at most
`maxResults` files (5 files with `maxResults: 2` give 3 pages at least),
every file once, at most 10 pages before failing.

## What to know

* The suite really writes files: point it at a local implementation, an
  emulator or a test bucket, with a `rootPath` on a shared bucket. A failed
  run leaves files behind; `list_files` expects exactly its 3 files under
  `<rootPath>/test/list_files/yes`.
* Create the bucket first for a local or simulated implementation.
* The admin sdk implementation returns every file in one page: its emulator
  run fails `list_files_pages` (known, `getFiles` ignores `maxResults` and the
  page token).

## Dev menu

`firebaseStorageMainMenu` (`menu/storage_client_menu.dart`) is a
[`tekartik_app_dev_menu`](https://github.com/tekartik/app_common_utils.dart)
console menu to list, write, read and delete `<rootPath>/file0.txt` of a live
bucket:

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/menu/storage_client_menu.dart';

Future<void> main(List<String> args) async {
  var app = FirebaseLocal().initializeApp();
  var storage = newStorageServiceMemory().storage(app);
  await storage.bucket('my_bucket').create();
  await mainMenu(args, () {
    firebaseStorageMainMenu(
      context: StorageMainMenuContext(
        storage: storage,
        bucket: 'my_bucket',
        rootPath: 'tests/manual',
      ),
    );
  });
}
```

More in the [package skill](skills/tekartik-firebase-storage-test-suite/SKILL.md).
