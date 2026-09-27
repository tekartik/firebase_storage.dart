---
name: tekartik-firebase-storage-implement
description: >-
  Use when writing a new backend for the tekartik_firebase_storage abstraction
  (or a decorator/fake over it): FirebaseStorageServiceMixin,
  appOptionsGetStorageBucket, storage_mixin.dart, FirebaseStorageMixin /
  StorageMixin, BucketMixin, FileMixin, FileMetadataMixin, ReferenceMixin,
  FirebaseProductServiceMixin.getInstance, FirebaseAppProductMixin, and what a
  Storage, Bucket, File, FileMetadata or GetFilesResponse implementation must
  provide (upload/download with StorageUploadFileOptions contentType and
  cacheControl, getFiles paging with GetFilesOptions.pageToken).
---

# Implementing a Firebase Storage backend (tekartik_firebase_storage)

`tekartik_firebase_storage` only declares the contract; each backend
(`storage_fs`, `storage_flutter`, `storage_node`, `storage_rest`,
`storage_sim`) implements it with mixins that throw `UnimplementedError` for
everything not overridden, so the abstraction can grow without breaking
existing implementations. The same mixins are the cheapest way to write a
fake, a decorator or a partial in-process backend.

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
* Two imports for an implementer: `package:tekartik_firebase_storage/storage.dart`
  (the contract plus `package:tekartik_firebase/firebase.dart`) and
  `package:tekartik_firebase_storage/storage_mixin.dart`, which adds exactly
  `FirebaseStorageServiceMixin` (alias `StorageServiceMixin`) and
  `appOptionsGetStorageBucket`. The app/product plumbing
  (`FirebaseProductServiceMixin`, `FirebaseAppProductMixin`) comes from
  `package:tekartik_firebase/firebase_mixin.dart`. Keep your own classes in
  `lib/src/` and export only a `StorageService` getter (`storageServiceXxx`)
  from the public library.
* The service is a process singleton implementing
  `FirebaseStorageService.storage(App app)`. Mix in
  `FirebaseProductServiceMixin<FirebaseStorage>` and return
  `getInstance(app, () => XxxStorage(this, app))`: it caches one product per
  app, registers it on the app (so `app.storage()` and
  `app.getProduct<FirebaseStorage>()` find it) and disposes it when the app is
  deleted. Check the app type there (`assert(app is FirebaseAppSim)`, `if (app
  is! AppLocal) throw StateError(...)`) when the backend needs a specific one.
* The product mixes in `FirebaseAppProductMixin<FirebaseStorage>` (gives
  `type` and `dispose`) and `FirebaseStorageMixin` (alias `StorageMixin`),
  then provides `app`, `service` and at least `bucket([name])`. Leave
  `ref([path])` to the mixin (it throws `UnimplementedError`) unless the
  backend really produces download urls.
* Default bucket: `bucket()` with no name must resolve to
  `appOptionsGetStorageBucket(app.options)`, i.e.
  `AppOptions.storageBucket` or `'<projectId>.appspot.com'`. Do not invent
  another fallback: the shared tests and the callers assume that rule.
* `BucketMixin` needs `name`, `file(path)`, `exists()`, `create()` and
  `getFiles([options])`. `file(path)` must be synchronous and side effect
  free; normalize the path there (strip a leading `/`, keep `/` separators
  even on Windows) so `file('a/b')` and `file('/a/b')` are the same object.
* `FileMixin` implements `writeAsBytes`, `writeAsString`, `readAsBytes`,
  `readAsString` and the deprecated `save` on top of `upload` and the
  deprecated `download`: overriding `upload(bytes, {options})` plus
  `readAsBytes()` (and forwarding `download() => readAsBytes()` for legacy
  callers) gives a complete `File`. Also override `name`, `bucket`,
  `exists()`, `delete()`, `getMetadata()` and the `metadata` getter.
* `metadata` is a cache, not a fetch: return the `FileMetadata` captured by
  `getFiles()` (or `null`), and keep `getMetadata()` as the authoritative
  round trip. When the backend listing already returns the object metadata,
  keep it on the listed files rather than `null`: callers would otherwise
  make one `getMetadata()` call per file. `getMetadata()` must throw when the
  object does not exist.
* `FileMetadataMixin` gives you the `toString()` and the
  `UnimplementedError` defaults; a metadata class provides `size`,
  `dateUpdated` (UTC), `md5Hash` and the nullable `contentType`. When the
  caller gave no `StorageUploadFileOptions.contentType`, guess it with
  `firebaseStorageContentTypeFromFilename(name)` from
  `package:tekartik_firebase_storage/utils/content_type.dart` and fall back to
  `firebaseStorageDefaultContentType`.
* `StorageUploadFileOptions.cacheControl` is stored with the object and read
  back through `FileMetadata.cacheControl` (`FileMetadataMixin` returns
  `null`, meaning none was set, until overridden). Map it to the backend
  field (`cacheControl` of the Cloud Storage object resource,
  `SettableMetadata.cacheControl` on Flutter, the `metadata` of a node
  `save`); a local backend keeps it next to the content type. An upload
  replaces the metadata: uploading without it must leave no cache control.
  Never guess a value.
* `getFiles` must be recursive under `options.prefix` (a plain string prefix,
  not a folder), return names relative to the bucket root with `/`
  separators, honour `maxResults` and resume from `options.pageToken`. Build
  the result with the `GetFilesResponse(files: ..., nextQuery: ...)` factory,
  `nextQuery` being a `GetFilesOptions` copy carrying the next `pageToken`,
  or `null` when the listing is over.
* Paths and links: `StorageFileRef` from
  `package:tekartik_firebase_storage/utils/link.dart` parses and builds
  `gs://<bucket>/<path>` urls; use it in a `ReferenceMixin` implementation
  instead of hand-splitting urls.
* Validate with the shared suite of the `tekartik_firebase_storage_test`
  package (same repo, `path: storage_test`): `runStorageTests(firebase: ...,
  storageService: ..., options: AppOptions(...), storageOptions:
  TestStorageOptions(bucket: ...))`. It is the definition of "conforming".
* Do not throw custom exception types from public members: callers only get
  the contract, so signal a missing object through `exists()` returning
  `false` and let read/delete failures surface the underlying exception.

## Examples

### A minimal in-memory implementation

Everything not overridden keeps throwing `UnimplementedError`, which is the
intended behaviour for a partial backend.

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/storage_mixin.dart';
import 'package:tekartik_firebase_storage/utils/content_type.dart';

/// Public entry point of the implementation package.
final storageServiceExample = ExampleStorageService();

class ExampleStorageService
    with FirebaseProductServiceMixin<FirebaseStorage>, FirebaseStorageServiceMixin
    implements FirebaseStorageService {
  final data = <String, Map<String, Uint8List>>{};

  @override
  FirebaseStorage storage(App app) =>
      getInstance(app, () => ExampleStorage(this, app));
}

class ExampleStorage
    with FirebaseAppProductMixin<FirebaseStorage>, FirebaseStorageMixin {
  @override
  final ExampleStorageService service;
  @override
  final FirebaseApp app;

  ExampleStorage(this.service, this.app);

  @override
  Bucket bucket([String? name]) =>
      ExampleBucket(this, name ?? appOptionsGetStorageBucket(app.options));
}

class ExampleBucket with BucketMixin {
  final ExampleStorage storage;
  @override
  final String name;

  ExampleBucket(this.storage, this.name);

  Map<String, Uint8List>? get content => storage.service.data[name];

  @override
  File file(String path) =>
      ExampleFile(this, path.startsWith('/') ? path.substring(1) : path);

  @override
  Future<bool> exists() async => content != null;

  @override
  Future<void> create() async => storage.service.data[name] ??= {};

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) async {
    var names = (content?.keys.toList() ?? <String>[])
      ..removeWhere((name) => !name.startsWith(options?.prefix ?? ''))
      ..sort();
    var maxResults = options?.maxResults ?? 1000;
    String? nextPageToken;
    if (names.length > maxResults) {
      nextPageToken = names[maxResults];
      names = names.sublist(0, maxResults);
    }
    return GetFilesResponse(
      files: [for (var name in names) file(name)],
      nextQuery: nextPageToken == null
          ? null
          : (options ?? GetFilesOptions()).copyWith(pageToken: nextPageToken),
    );
  }
}

class ExampleFile with FileMixin {
  @override
  final ExampleBucket bucket;
  @override
  final String name;

  ExampleFile(this.bucket, this.name);

  @override
  FileMetadata? get metadata => null;

  String? _contentType;
  String? _cacheControl;

  @override
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options}) async {
    await bucket.create();
    _contentType =
        options?.contentType ??
        firebaseStorageContentTypeFromFilename(name) ??
        firebaseStorageDefaultContentType;
    // Replaced on each upload, never guessed.
    _cacheControl = options?.cacheControl;
    bucket.content![name] = bytes;
  }

  @override
  Future<Uint8List> readAsBytes() async {
    var bytes = bucket.content?[name];
    if (bytes == null) {
      throw StateError('file $name not found in ${bucket.name}');
    }
    return bytes;
  }

  @override
  Future<bool> exists() async => bucket.content?[name] != null;

  @override
  Future<void> delete() async => bucket.content?.remove(name);

  @override
  Future<FileMetadata> getMetadata() async => ExampleFileMetadata(
    size: (await readAsBytes()).length,
    contentType: _contentType,
    cacheControl: _cacheControl,
  );
}

class ExampleFileMetadata with FileMetadataMixin {
  @override
  final int size;
  @override
  final String? contentType;
  @override
  final String? cacheControl;
  @override
  final DateTime dateUpdated = DateTime.now().toUtc();
  @override
  final String md5Hash = '';

  ExampleFileMetadata({
    required this.size,
    required this.contentType,
    this.cacheControl,
  });
}
```

### A decorator that logs every read and write

```dart
import 'dart:typed_data';

import 'package:tekartik_firebase_storage/storage.dart';

class LoggerFile with FileMixin {
  final File file;

  LoggerFile(this.file);

  @override
  String get name => file.name;

  @override
  Bucket get bucket => file.bucket;

  @override
  FileMetadata? get metadata => file.metadata;

  @override
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options}) {
    print('upload ${file.name} (${bytes.length} bytes)');
    return file.upload(bytes, options: options);
  }

  @override
  Future<Uint8List> readAsBytes() async {
    var bytes = await file.readAsBytes();
    print('read ${file.name} (${bytes.length} bytes)');
    return bytes;
  }

  @override
  Future<bool> exists() => file.exists();

  @override
  Future<void> delete() => file.delete();

  @override
  Future<FileMetadata> getMetadata() => file.getMetadata();
}
```

### A reference producing a gs:// download url

```dart
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';

class ExampleReference with ReferenceMixin {
  final String bucketName;
  final String path;

  ExampleReference(this.bucketName, this.path);

  @override
  Future<String> getDownloadUrl() async =>
      StorageFileRef(bucketName, path).toLink().toString();
}
```

## Common mistakes

* Creating the product directly instead of through
  `getInstance(app, ...)`: the app then has no registered product and
  `app.storage()` throws a `StateError`.
* Returning a different `Storage` for the same `App`, or holding a service
  getter that rebuilds the service on every access (the per-app cache lives
  in the service instance).
* Resolving the default bucket with anything else than
  `appOptionsGetStorageBucket(app.options)`.
* Overriding `save()` / `download()` only: the modern `writeAs*` / `readAs*`
  members go through `upload` and `readAsBytes`.
* Making `metadata` fetch the metadata (it must stay a cheap cached getter)
  or having `getMetadata()` succeed on a missing object.
* Dropping `StorageUploadFileOptions.cacheControl`, or keeping the previous
  one when a file is uploaded again without it. The shared
  `file_with_cache_control` test checks both.
* Ignoring `pageToken` in `getFiles`, or returning a non-null `nextQuery`
  when the last page has been returned: callers loop until it is `null`.
