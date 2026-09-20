---
name: tekartik-firebase-storage-fs-setup
description: >-
  Use when backing tekartik_firebase_storage with a file system instead of a
  real cloud bucket (unit tests, local tools, sim servers) with
  tekartik_firebase_storage_fs: storageServiceMemory, newStorageServiceMemory,
  newStorageMemory, newStorageServiceFs(fileSystem:, basePath:),
  storageServiceIo, createStorageServiceIo(basePath:), the storage_fs.dart /
  storage_fs_io.dart imports, the AppLocal requirement of FirebaseLocal /
  newFirebaseAppLocal, the data/ + meta/ on-disk layout and running the
  tekartik_firebase_storage_test suite on it.
---

# tekartik_firebase_storage_fs: storage on a file system

`tekartik_firebase_storage_fs` implements `tekartik_firebase_storage` on top
of an `fs_shim` `FileSystem`: in memory (tests, sim servers) or on the real
`dart:io` file system (local tools, offline apps). Objects become plain files
under `data/`, their metadata a JSON file under `meta/`.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_storage_fs:
      git:
        url: https://github.com/tekartik/firebase_storage.dart
        path: storage_fs
      version: '>=0.4.0'
  ```
  It brings `tekartik_firebase_storage` and `tekartik_firebase_local`;
  declare them too when you import them directly.
* Imports: `package:tekartik_firebase_storage_fs/storage_fs.dart` re-exports
  `package:tekartik_firebase_storage/storage.dart` (hence
  `tekartik_firebase/firebase.dart`) and adds the memory helpers;
  `package:tekartik_firebase_storage_fs/storage_fs_io.dart` re-exports
  `storage_fs.dart` and adds the `dart:io` ones. Import the `_io` library only
  from VM/Flutter-native code; the memory library works everywhere (including
  the browser). Never import `package:tekartik_firebase_storage_fs/src/...`.
* The app must be a local app: `FirebaseLocal().initializeApp(...)`,
  `newFirebaseAppLocal()` or `newFirebaseAppMemory()` from
  `package:tekartik_firebase_local/firebase_local.dart`. Any other app type
  makes `storage(app)` throw `StateError('App must be of type AppLocal')`.
* Four ways to get a `StorageService`:
  - `storageServiceMemory`: a process-wide in-memory service, shared by every
    caller (handy, but state leaks between tests).
  - `newStorageServiceMemory()`: a fresh, isolated in-memory service; the
    right default in `setUp`.
  - `storageServiceIo` / `createStorageServiceIo(basePath: ...)`: the real
    `dart:io` file system, globally or rooted at `basePath`.
  - `newStorageServiceFs(fileSystem: ..., basePath: ...)`: any `fs_shim`
    `FileSystem` (memory, io, an idb one...).
  `newStorageMemory({firebaseAppName})` goes one step further and returns a
  ready `Storage` with its own private `FirebaseLocal` app: one line for a
  test. Delete it with `await storage.app.delete()`.
* A service caches one `Storage` per app, so keep the service in a variable
  (or use the global getter) rather than building a new one per call:
  two services never see each other's data, even in memory.
* On-disk layout, for bucket `b` and object `dir/f.txt`:
  `<root>/b/data/dir/f.txt` for the bytes and `<root>/b/meta/dir/f.txt.json`
  for the metadata, where `<root>` is `basePath` when given, otherwise
  `<app.localPath>/storage` (that is
  `.dart_tool/tekartik_firebase_local/<projectId>/storage` for a default
  `FirebaseLocal`). Parent directories are created on demand by `upload`.
* `storage.bucket()` with no name is `'_default'` here (this implementation
  does not apply the `<projectId>.appspot.com` fallback), so pass the bucket
  name explicitly when the same code also runs against a real backend.
  `bucket.exists()` is `false` until something is written, except for the
  bucket named `app.options.storageBucket`, which is auto-created; call
  `await bucket.create()` first when a test asserts on `exists()`.
* A leading `/` in a file path is stripped: `bucket.file('/a/b')` and
  `bucket.file('a/b')` are the same object. Paths always use `/`, converted to
  the native separator internally.
* Metadata is written on every upload: `md5Hash` (hex), `size`,
  `dateUpdated` (UTC) and `contentType`, taken from
  `StorageUploadFileOptions.contentType`, else guessed from the extension,
  else `application/octet-stream`. `getFiles()` fills `file.metadata` (and
  regenerates a missing meta file, printing a line); `bucket.file(path)`
  returns a `File` whose `metadata` is `null`, use `getMetadata()`.
* `getFiles()` lists recursively under `prefix`, sorted by path, with a
  default `maxResults` of 1000 and a real `pageToken`: loop while
  `response.nextQuery != null`. Deleted or missing prefixes yield an empty
  page instead of throwing.
* `storage.ref(path)` expects a full `gs://<bucket>/<path>` link (build it
  with `StorageFileRef` from
  `package:tekartik_firebase_storage/utils/link.dart`) and
  `getDownloadUrl()` returns a `file://` url of the backing file, which only
  makes sense with the io file system.
* Reads of a missing file throw the underlying `fs_shim`
  `FileSystemException`; prefer `await file.exists()`. The store is not
  transactional and not process-safe: one io service per directory at a time.
* Testing: `newStorageServiceMemory()` per test group keeps tests hermetic;
  the shared suite of `tekartik_firebase_storage_test` (`runStorageTests` /
  `runStorageAppTests`) runs against either flavour, as `test/` of this
  package does.

## Examples

### One-line storage in a unit test

```dart
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:test/test.dart';

void main() {
  test('read write', () async {
    var storage = newStorageMemory();
    var file = storage.bucket('my_bucket').file('dir/hello.txt');
    await file.writeAsString('hello');
    expect(await file.readAsString(), 'hello');
    expect((await file.getMetadata()).contentType, 'text/plain');
    await storage.app.delete();
  });
}
```

### Isolated in-memory service bound to a local app

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

Future<void> main() async {
  var storageService = newStorageServiceMemory();
  var app = FirebaseLocal().initializeApp(
    options: AppOptions(projectId: 'my_project', storageBucket: 'my_bucket'),
  );
  var storage = storageService.storage(app);
  var bucket = storage.bucket('my_bucket');
  await bucket.create();
  await bucket.file('notes/todo.txt').writeAsString('write the skill');
  var response = await bucket.getFiles(GetFilesOptions(prefix: 'notes/'));
  print(response.files.map((file) => file.name).toList());
  await app.delete();
}
```

### Real files on disk, rooted at a directory

```dart
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs_io.dart';

Future<void> main() async {
  // Objects land in .local/storage/<bucket>/data/... and meta/...
  var storageService = createStorageServiceIo(
    basePath: join('.local', 'storage'),
  );
  var app = newFirebaseAppLocal(
    options: AppOptions(projectId: 'local_tool', storageBucket: 'assets'),
  );
  var bucket = storageService.storage(app).bucket('assets');
  await bucket.create();
  await bucket.file('logo.png').writeAsBytes(Uint8List.fromList([1, 2, 3]));
  print(await bucket.file('logo.png').exists());
  await app.delete();
}
```

### Any fs_shim file system

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

Future<void> main() async {
  var fileSystem = newFileSystemMemory();
  var storageService = newStorageServiceFs(
    fileSystem: fileSystem,
    basePath: 'base',
  );
  var storage = storageService.storage(newFirebaseAppLocal());
  await storage.bucket().file('test.txt').writeAsString('text');
  // The backing file, '_default' being the default bucket name here.
  print(await fileSystem.file('base/_default/data/test.txt').readAsString());
}
```

### Running the shared storage test suite on it

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs_io.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

var bucketName = 'my_bucket';

void main() {
  group('storage_fs_io', () {
    runStorageTests(
      firebase: FirebaseLocal(),
      storageService: storageServiceIo,
      options: AppOptions(projectId: 'storage_fs_io', storageBucket: bucketName),
      storageOptions: TestStorageOptions(bucket: bucketName),
    );
  });
}
```

## Common mistakes

* Passing a non local app (flutter, rest, node, sim) to `storage(app)`.
* Expecting `storage.bucket()` to be `<projectId>.appspot.com`: it is
  `_default` here.
* Asserting `await bucket.exists()` before anything was written or
  `create()`d.
* Sharing `storageServiceMemory` across tests and being surprised by
  leftovers; use `newStorageServiceMemory()` or `newStorageMemory()`.
* Importing `storage_fs_io.dart` from web code, or expecting the `file://`
  `getDownloadUrl()` of the memory file system to be openable.
* Two services (even two `newStorageServiceMemory()`) over the same app:
  each has its own store, and the app's registered product is the last one
  created.
