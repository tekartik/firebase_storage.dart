---
name: tekartik-firebase-storage-files
description: >-
  Use when reading, writing, listing or deleting cloud storage objects through
  the platform neutral tekartik_firebase_storage API: FirebaseStorage /
  Storage, storage.bucket(name), app.storage(), Bucket.file / exists / create /
  getFiles, File.upload / writeAsBytes / writeAsString / readAsBytes /
  readAsString / exists / delete / getMetadata, StorageUploadFileOptions
  contentType / cacheControl (Cache-Control header), FileMetadata size /
  dateUpdated / md5Hash / contentType / cacheControl, GetFilesOptions and
  GetFilesResponse.nextQuery pagination, Reference.getDownloadUrl,
  StorageFileRef gs:// links and firebaseStorageContentTypeFromFilename.
---

# Firebase Storage files and buckets (tekartik_firebase_storage)

`tekartik_firebase_storage` is the backend neutral Cloud Storage abstraction
of the tekartik Firebase stack: `Storage` (a typedef of `FirebaseStorage`)
hands out `Bucket`s, a `Bucket` hands out `File`s, and a `File` uploads,
downloads, deletes and describes one object. No implementation ships here; a
`FirebaseStorageService` from an implementation package binds it to an app.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_storage:
      git:
        url: https://github.com/tekartik/firebase_storage.dart
        path: storage
      version: '>=0.4.0'
  ```
* Import `package:tekartik_firebase_storage/storage.dart`; it re-exports
  `package:tekartik_firebase/firebase.dart`, so `Firebase`, `FirebaseApp` /
  `App` and `AppOptions` come with it. Never import
  `package:tekartik_firebase_storage/src/...`; `storage_mixin.dart` is for
  implementers (see the `tekartik-firebase-storage-implement` skill).
* This package alone cannot store anything: add an implementation and use its
  `StorageService` getter, then keep every shared function typed on `Storage`,
  `Bucket` or `File`. Implementations: `tekartik_firebase_storage_fs`
  (in-memory and `dart:io` file system, same repo, `path: storage_fs`),
  `tekartik_firebase_storage_sim` (websocket client, `path: storage_sim`),
  `tekartik_firebase_storage_flutter`, `tekartik_firebase_storage_node`,
  `tekartik_firebase_storage_rest`.
* Get the product with `storageService.storage(app)`. It is cached per app
  and registered on it, so `app.storage()` (extension
  `TekartikFirebaseStorageFirebaseAppExt`) returns the same instance
  afterwards and throws a `StateError` when no storage was created for that
  app. `FirebaseStorage.instance` only resolves the product of the most
  recently initialized app: prefer passing the `Storage` around. `storage.app`
  and `storage.service` walk back to the app and the service.
* `storage.bucket()` returns the default bucket (derived from
  `AppOptions.storageBucket`, see `appOptionsGetStorageBucket`);
  `storage.bucket(name)` targets a named bucket, without any `gs://` prefix.
  Set `AppOptions(projectId: ..., storageBucket: ...)` at `initializeApp` time
  rather than repeating the bucket name everywhere.
* `bucket.exists()` and `bucket.create()` are mostly meaningful on local /
  simulated implementations, where creating the bucket first is usually
  required; against a real backend, buckets are created in the console and
  `create()` may throw `UnimplementedError`.
* `bucket.file(path)` is purely local: `path` is the full object path inside
  the bucket (`'dir/sub/file.txt'`, no leading `/`), nothing is fetched until
  an operation is awaited. `file.name` gives that path back and `file.bucket`
  the owning bucket.
* Write with `file.upload(bytes, options: StorageUploadFileOptions(contentType:
  ..., cacheControl: ...))`, `file.writeAsBytes(bytes)` (`Uint8List`) or
  `file.writeAsString(text)` (UTF-8). Read with `file.readAsBytes()` /
  `file.readAsString()`; both load the whole object in memory, so keep them
  for small files. `file.exists()` and `file.delete()` complete the set.
  `save()` and `download()` are deprecated: use the `writeAs*` / `readAs*`
  pair.
* Content type: pass it explicitly through `StorageUploadFileOptions` when you
  know it. Implementations that guess use
  `firebaseStorageContentTypeFromFilename(name)` from
  `package:tekartik_firebase_storage/utils/content_type.dart` (`null` for an
  unknown extension) and fall back to `firebaseStorageDefaultContentType`
  (`'application/octet-stream'`).
* Cache control: `StorageUploadFileOptions(cacheControl: ...)` stores a
  `Cache-Control` value on the object, and Cloud Storage sends it as the
  header of its downloads (the Storage emulator does on every download url).
  Without it the backend default applies (the emulator sends an empty
  header). `storage_fs` and `storage_sim` only store it. It is part of the
  upload: uploading again without it removes it, so pass it on every write.
  Usual values: `'public, max-age=31536000, immutable'` for a file whose name
  changes with its content (versioned or hashed name, never overwritten),
  `'no-cache'` for a small file that changes in place (a pointer or meta
  file, revalidated with its ETag on each read). Never mark a private or per
  user file `public`: a CDN in front may serve it to others.
* Metadata: `await file.getMetadata()` returns a `FileMetadata` with `size`,
  `dateUpdated`, `md5Hash`, and a nullable `contentType` and `cacheControl`
  (`null` when none was set); it throws when the object does not exist. The `file.metadata` *getter* is only a cache filled
  by `bucket.getFiles()` on some implementations: never read it on a `File`
  built with `bucket.file(path)`, and null-check it on listed files.
* Listing: `bucket.getFiles(GetFilesOptions(prefix: 'dir/', maxResults: 50,
  autoPaginate: false))` returns a `GetFilesResponse` with `files` and a
  `nextQuery`. Loop while `nextQuery != null`, passing it straight back to
  `getFiles`; do not stop on an empty `files` page. The listing is recursive
  (`prefix` matches sub paths too) and `prefix` is a plain string prefix, not
  a directory. `GetFilesOptions.copyWith(...)` derives a variant of a query.
* `storage.ref(path)` / `Reference.getDownloadUrl()` is optional: many
  implementations throw `UnimplementedError`, and what `path` means (bucket
  relative path or full `gs://` url) is implementation specific. Build and
  parse `gs://bucket/path` urls with `StorageFileRef` from
  `package:tekartik_firebase_storage/utils/link.dart`
  (`StorageFileRef(bucket, path)`, `StorageFileRef.fromLink(uri)`, `toLink()`,
  `toString()`); it percent-encodes paths with spaces for you.
* There is no exported storage exception type: a missing object, a missing
  bucket or a permission error throws an implementation specific exception.
  Probe with `exists()` instead of catching, and never assume
  `on SomeStorageException`.
* Tests: write them against `newStorageMemory()` /
  `storageServiceMemory` of `tekartik_firebase_storage_fs` and keep the real
  backend for the app; `tekartik_firebase_storage_test` runs the shared suite
  against any implementation.

## Examples

### Wiring an app and a storage service

```dart
import 'package:tekartik_firebase_storage/storage.dart';

/// [firebase] and [storageService] come from an implementation package
/// (storage_fs, storage_flutter, storage_node, storage_rest, storage_sim).
Storage openStorage(Firebase firebase, FirebaseStorageService storageService) {
  var app = firebase.initializeApp(
    options: AppOptions(
      projectId: 'my_project',
      storageBucket: 'my_project.appspot.com',
    ),
  );
  var storage = storageService.storage(app);
  // Same instance, from the app itself.
  assert(identical(app.storage(), storage));
  return storage;
}
```

### Text round trip

```dart
import 'package:tekartik_firebase_storage/storage.dart';

Future<String?> readOrCreate(Storage storage, String path) async {
  var file = storage.bucket().file(path);
  if (await file.exists()) {
    return file.readAsString();
  }
  await file.writeAsString('hello');
  return null;
}
```

### Upload bytes with a content type and read the metadata back

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/content_type.dart';

Future<FileMetadata> uploadImage(
  Bucket bucket,
  String path,
  Uint8List bytes,
) async {
  var file = bucket.file(path);
  await file.upload(
    bytes,
    options: StorageUploadFileOptions(
      contentType:
          firebaseStorageContentTypeFromFilename(path) ??
          firebaseStorageDefaultContentType,
    ),
  );
  var metadata = await file.getMetadata();
  print('${file.name}: ${metadata.size} bytes, ${metadata.contentType}');
  return metadata;
}
```

### Publishing an immutable file and the small file pointing to it

The data file is written first and never changes (its name carries a version),
so it can be cached forever; the pointer is revalidated on each read. A reader
never gets a pointer to a file that is not there yet.

```dart
import 'dart:convert';

import 'package:tekartik_firebase_storage/storage.dart';

Future<void> publish(Bucket bucket, int version, String data) async {
  await bucket
      .file('export/export_$version.jsonl')
      .upload(
        utf8.encode(data),
        options: StorageUploadFileOptions(
          contentType: 'application/x-ndjson',
          cacheControl: 'public, max-age=31536000, immutable',
        ),
      );
  var meta = bucket.file('export/export_meta.json');
  await meta.upload(
    utf8.encode(jsonEncode({'version': version})),
    options: StorageUploadFileOptions(
      contentType: 'application/json',
      cacheControl: 'no-cache',
    ),
  );
  assert((await meta.getMetadata()).cacheControl == 'no-cache');
}
```

### Listing a prefix, page by page

```dart
import 'package:tekartik_firebase_storage/storage.dart';

Future<List<String>> listPaths(Bucket bucket, String prefix) async {
  var paths = <String>[];
  GetFilesOptions? query = GetFilesOptions(
    prefix: prefix,
    maxResults: 100,
    autoPaginate: false,
  );
  while (query != null) {
    var response = await bucket.getFiles(query);
    for (var file in response.files) {
      // metadata is only a cache filled by getFiles, it can be null.
      paths.add('${file.name} (${file.metadata?.size ?? -1})');
    }
    query = response.nextQuery;
  }
  return paths;
}
```

### Deleting every object under a prefix

```dart
import 'package:tekartik_firebase_storage/storage.dart';

Future<int> deletePrefix(Bucket bucket, String prefix) async {
  var count = 0;
  GetFilesOptions? query = GetFilesOptions(prefix: prefix, autoPaginate: false);
  while (query != null) {
    var response = await bucket.getFiles(query);
    for (var file in response.files) {
      await file.delete();
      count++;
    }
    query = response.nextQuery;
  }
  return count;
}
```

### gs:// links

```dart
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';

/// 'gs://my_bucket/images/my photo.jpg' -> the file it points to.
File fileFromLink(Storage storage, String link) {
  var ref = StorageFileRef.fromLink(Uri.parse(link));
  return storage.bucket(ref.bucket).file(ref.path);
}

String linkOf(File file) =>
    StorageFileRef(file.bucket.name, file.name).toLink().toString();
```

## Common mistakes

* Reading `file.metadata` on a `bucket.file(path)` reference instead of
  awaiting `getMetadata()`.
* Stopping a listing loop on an empty `files` page rather than on a null
  `nextQuery`, or relying on `autoPaginate` being honoured.
* Passing `gs://bucket/path` to `bucket.file(...)` (it wants a bucket
  relative path) or a `gs://` prefix to `storage.bucket(...)`.
* Expecting `storage.ref(...)`, `getDownloadUrl()` or `bucket.create()` to
  work everywhere: they are optional and throw `UnimplementedError` on
  several implementations.
* Reading a large object with `readAsBytes()`: everything is in memory.
* Rewriting a file with `writeAsString` / `writeAsBytes` (no options) and
  expecting its `cacheControl` to survive: the new upload has none.
* `public, immutable` on a file that is overwritten under the same name:
  browsers and CDNs keep serving the old content for a year.
* Calling `storageService.storage(app)` from a freshly built service each
  time; keep one service instance per process.
