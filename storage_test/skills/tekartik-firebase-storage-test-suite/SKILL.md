---
name: tekartik-firebase-storage-test-suite
description: >-
  Use when validating a tekartik_firebase_storage implementation (storage_fs,
  storage_sim, storage_flutter, storage_node, storage_rest or your own) against
  the shared conformance suite of tekartik_firebase_storage_test:
  runStorageTests(firebase:, storageService:, options:, storageOptions:),
  runStorageAppTests(app, ...), TestStorageOptions(bucket:, rootPath:,
  skipDefaultBucketExists:), copyWith / withAddedPath, and the interactive
  firebaseStorageMainMenu / StorageMainMenuContext dev menu of
  menu/storage_client_menu.dart.
---

# Shared storage test suite (tekartik_firebase_storage_test)

`tekartik_firebase_storage_test` is the conformance suite every
`tekartik_firebase_storage` backend runs against: one call defines a dozen
`test()`s that write, read, list, delete and describe objects through the
public API only. It also ships an interactive dev menu to poke at a live
bucket by hand.

## Guidelines

* Dev dependency (git, not on pub.dev):
  ```yaml
  dev_dependencies:
    tekartik_firebase_storage_test:
      git:
        url: https://github.com/tekartik/firebase_storage.dart
        path: storage_test
      version: '>=0.4.1'
  ```
  It brings `tekartik_firebase_storage` and `dev_test`; add `test` yourself,
  the suite does not re-export it.
* Import `package:tekartik_firebase_storage_test/storage_test.dart`: it
  re-exports `package:tekartik_firebase_storage/storage.dart` (so `Storage`,
  `AppOptions`, `GetFilesOptions`... come with it) and adds
  `TestStorageOptions`, `runStorageTests` and `runStorageAppTests`. Import
  `package:test/test.dart` too for `group`, `setUpAll` and `tearDownAll`.
* Two entry points, both called from `main()` (or inside a `group` callback),
  never from inside a `test()`: they create the app/storage and register the
  tests as a side effect.
  - `runStorageTests(firebase: ..., storageService: ..., options:
    AppOptions(...), storageOptions: TestStorageOptions(...))` initializes its
    own app on the given `Firebase` and deletes it in `tearDownAll`.
  - `runStorageAppTests(app, storageService: ..., storageOptions: ...)` uses
    an app you already own (a sim client app, a Flutter app, an app you must
    configure first) and leaves its lifecycle to you.
  `run(...)` and `runApp(...)` are the deprecated spellings of the same two.
* `TestStorageOptions(bucket: ..., rootPath: ..., skipDefaultBucketExists:
  ...)`:
  - `bucket` is the bucket the suite works in; when null it falls back to the
    app's `AppOptions.storageBucket` (or `<projectId>.appspot.com`).
  - `rootPath` prefixes every object path the suite touches; use it to sandbox
    a shared or real bucket, ideally with a unique run id, since the listing
    test asserts on the exact content of `<rootPath>/test/list_files/yes`.
  - `skipDefaultBucketExists: true` skips the `await bucket.exists()` is
    `true` assertion for backends that cannot answer it; the "a dummy bucket
    does not exist" assertion always runs.
  - `options.copyWith(rootPath:, skipDefaultBucketExists:)` and
    `options.withAddedPath('sub')` (extension `TestStorageOptionsExt`) derive
    a variant, the latter appending to the current `rootPath`.
* Create the bucket before the suite runs when the implementation needs it
  (`await storageService.storage(app).bucket(name).create()` in `main`, or in
  a `setUpAll`): the suite writes immediately and only checks existence.
* What conformance means here, and what the suite will fail on: the service
  must return the same `Storage` for the same app and register it as the app
  product (`app.getProduct<FirebaseStorage>()`); `file.exists()` must be
  `false` for an unknown path and `true` right after a write; `writeAsString`
  /`readAsString`/`readAsBytes`/`delete` must round trip; `getMetadata()` must
  throw on a missing object and then report `size`, `dateUpdated`, `md5Hash`
  and a `contentType` of `text/plain` for a `.txt` upload, of
  `application/octet-stream` for a `.bin` one, and whatever
  `StorageUploadFileOptions.contentType` asked for; `getFiles` must page
  through a prefix with `maxResults: 2` and `autoPaginate: false`, walking
  sub-directories, exposing consistent `file.metadata` (or `null`) and an
  empty result for an unknown prefix.
* The suite really writes objects, so point it at a scratch bucket. Against a
  local backend (`tekartik_firebase_storage_fs` memory or io) it is hermetic
  and fast; against a real bucket give it a `rootPath` and expect leftovers
  from a failed run.
* Run it with `dart test` (add `@TestOn('vm')` for an io-only backend) or
  `flutter test`/`integration_test` for the Flutter implementation. Several
  flavours of the same backend are just several `group`s, each with its own
  service instance.
* Manual exploration: `package:tekartik_firebase_storage_test/menu/storage_client_menu.dart`
  exports `tekartik_app_dev_menu` plus the storage API and adds
  `firebaseStorageMainMenu(context: StorageMainMenuContext(storage: ...,
  bucket: ..., rootPath: ...))`, with `list_files`, `write_file`,
  `read_file`, `delete_file` and `read_metadata` items on `<rootPath>/file0.txt`.
  Wrap it in `await mainMenu(args, () { ... })` in a `tool/` or `example/`
  script; it is a console (and browser) menu, not a test.

## Examples

### Conformance suite for your own service

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var bucketName = 'my_bucket';

void main() {
  group('my_storage', () {
    // Replace with your own Firebase and StorageService implementation.
    runStorageTests(
      firebase: FirebaseLocal(),
      storageService: newStorageServiceMemory(),
      options: AppOptions(projectId: 'my_test', storageBucket: bucketName),
      storageOptions: TestStorageOptions(bucket: bucketName),
    );
  });
}
```

### Against an app you own, creating the bucket first

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var bucketName = 'my_bucket';

Future<void> main() async {
  var storageService = newStorageServiceMemory();
  var app = FirebaseLocal().initializeApp(
    options: AppOptions(projectId: 'my_test'),
  );

  setUpAll(() async {
    await storageService.storage(app).bucket(bucketName).create();
  });

  runStorageAppTests(
    app,
    storageService: storageService,
    storageOptions: TestStorageOptions(bucket: bucketName),
  );

  tearDownAll(() async {
    await app.delete();
  });
}
```

### Sandboxing a shared or remote bucket

```dart
import 'package:tekartik_firebase_storage_test/storage_test.dart';

/// One scratch sub tree per run, and no bucket.exists() assertion for a
/// backend that cannot answer it.
TestStorageOptions scratchOptions(String bucket, String runId) =>
    TestStorageOptions(bucket: bucket, rootPath: 'tests')
        .withAddedPath(runId)
        .copyWith(skipDefaultBucketExists: true);
```

### Two flavours of the same backend in one file

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var bucketName = 'my_bucket';

void defineTests(String name, StorageService storageService) {
  group(name, () {
    runStorageTests(
      firebase: FirebaseLocal(),
      storageService: storageService,
      options: AppOptions(projectId: name, storageBucket: bucketName),
      storageOptions: TestStorageOptions(bucket: bucketName),
    );
  });
}

void main() {
  defineTests('memory', newStorageServiceMemory());
  defineTests(
    'fs',
    newStorageServiceFs(fileSystem: newFileSystemMemory(), basePath: 'base'),
  );
}
```

### Interactive dev menu against a live bucket

```dart
import 'package:tekartik_firebase_storage_test/menu/storage_client_menu.dart';

/// `dart run tool/storage_menu.dart` then pick an item.
Future<void> runMenu(List<String> args, FirebaseStorage storage) async {
  await mainMenu(args, () {
    firebaseStorageMainMenu(
      context: StorageMainMenuContext(
        storage: storage,
        bucket: 'test_bucket',
        rootPath: 'tests/manual',
      ),
    );
  });
}
```

## Common mistakes

* Calling `runStorageTests` / `runStorageAppTests` inside a `test()` body:
  they declare tests, they are not one.
* Forgetting to create the bucket for a local or simulated backend, then
  seeing every write fail.
* Running the suite twice in parallel on the same bucket and `rootPath`: the
  listing test asserts on the exact set of files under its prefix.
* Passing `storageOptions: TestStorageOptions()` with no `bucket` to a
  backend whose default bucket does not exist.
* Importing only `storage_test.dart` and missing `package:test/test.dart`
  for `group`/`setUpAll`/`tearDownAll`.
* Using the deprecated `run(...)` / `runApp(...)` in new code.
