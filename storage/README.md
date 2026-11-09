# tekartik_firebase_storage

Platform neutral Cloud Storage (Firebase Storage) API: a `Storage` gives
`Bucket`s, a `Bucket` gives `File`s, a `File` uploads, downloads, deletes and
describes one object. The same code runs on Flutter, REST, node, the admin
SDK, the file system and in memory (tests): pick the backend in the app.

This package has no backend of its own, see [Backends](#backends).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage
```

The in memory backend (file system based), for tests and tools:

```yaml
dev_dependencies:
  tekartik_firebase_storage_fs:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage_fs
```

```dart
import 'dart:convert';

// Re-exports package:tekartik_firebase_storage/storage.dart.
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

Future<void> main() async {
  // In memory: swap for the service of your platform (see below).
  var storage = newStorageMemory();
  var bucket = storage.bucket();
  if (!await bucket.exists()) {
    // Needed on local backends only.
    await bucket.create();
  }

  var file = bucket.file('notes/hello.txt');
  await file.upload(
    utf8.encode('Hello'),
    options: StorageUploadFileOptions(contentType: 'text/plain'),
  );
  print(await file.readAsString()); // Hello
  print((await file.getMetadata()).size); // 5

  var response = await bucket.getFiles(GetFilesOptions(prefix: 'notes/'));
  print(response.files.map((file) => file.name)); // (notes/hello.txt)
  await file.delete();
}
```

## Backends

The product comes from a `FirebaseStorageService`:
`storageService.storage(app)` (one instance per app, also returned by
`app.storage()`).

| Backend | Package (repo, path) | Service | Runs on |
|---|---|---|---|
| Memory, io file system | `tekartik_firebase_storage_fs` (firebase_storage.dart, `storage_fs`) | `newStorageServiceMemory()`, `storageServiceIo` (`newStorageMemory()` for a ready storage) | everywhere (tests, tools) |
| Sim | `tekartik_firebase_storage_sim` (firebase_storage.dart, `storage_sim`) | `storageServiceSim` | client of a sim server (web socket) |
| Flutter | `tekartik_firebase_storage_flutter` (firebase_flutter, `storage_flutter`) | `storageServiceFlutter` | Flutter (firebase_storage) |
| REST | `tekartik_firebase_storage_rest` (firebase_rest.dart, `storage_rest`) | `storageServiceRest` | Dart VM |
| Node | `tekartik_firebase_storage_node` (firebase_node.dart, `storage_node`) | `storageServiceNode` | node, Cloud Functions |
| Admin SDK | `tekartik_firebase_admin_sdk` (firebase_admin_sdk.dart, `firebase_admin_sdk`) | `firebaseStorageServiceAdminSdk` | Dart VM server |

All the repos are under `https://github.com/tekartik/`.

## When to use what

* `storage.bucket()`: the default bucket (`AppOptions.storageBucket`, or
  `<projectId>.appspot.com`); `storage.bucket(name)` for another one.
* `bucket.file(path)` does no I/O; `upload` (with `StorageUploadFileOptions`
  `contentType` and `cacheControl`), `writeAsBytes`, `writeAsString`,
  `readAsBytes`, `readAsString`, `exists`, `delete`, `getMetadata`.
* `bucket.getFiles(GetFilesOptions(prefix:, maxResults:, autoPaginate: false))`
  pages with `GetFilesResponse.nextQuery`.
* `gs://` links: `StorageFileRef` (`utils/link.dart`); a content type from a
  file name: `firebaseStorageContentTypeFromFilename` (`utils/content_type.dart`).
* The `Cache-Control` of an upload: [doc/cache_control.md](doc/cache_control.md).
* Backend authors: `storage_mixin.dart`, the shared tests of
  `tekartik_firebase_storage_test`.

## Common pitfalls

* `readAsBytes`/`readAsString` load the whole object in memory.
* `cacheControl` belongs to the upload: upload again without it and it is
  gone.
* A listing page can be empty while `nextQuery` is not null: loop on
  `nextQuery`. `prefix` is a plain string prefix, the listing is recursive.
* `file.metadata` is only filled on listed files by some backends; use
  `await file.getMetadata()`.
* No common exception type: test `exists()` rather than catching a backend
  specific error.
* `storage.ref(path).getDownloadUrl()` is not implemented by every backend.

## Skills

* [Files](skills/tekartik-firebase-storage-files/SKILL.md): buckets, files,
  metadata, listing, links, tests.
* [Implement](skills/tekartik-firebase-storage-implement/SKILL.md): writing a
  backend with the mixins.
