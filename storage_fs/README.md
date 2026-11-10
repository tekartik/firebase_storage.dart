# tekartik_firebase_storage_fs

Firebase Storage on a file system: the
[tekartik_firebase_storage](../storage/README.md) API (buckets, files,
metadata, listing) stored as plain files through
[fs_shim](https://pub.dev/packages/fs_shim). In memory for unit tests, on the
real file system for local tools and servers.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage_fs:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage_fs
```

```dart
// Re-exports package:tekartik_firebase_storage/storage.dart.
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';

Future<void> main() async {
  // A new in memory storage, on its own local app.
  var storage = newStorageMemory();
  var bucket = storage.bucket('my_bucket');

  await bucket.file('dir/hello.txt').writeAsString('hello');
  print(await bucket.file('dir/hello.txt').readAsString()); // hello

  var response = await bucket.getFiles(GetFilesOptions(prefix: 'dir/'));
  print(response.files.map((file) => file.name)); // (dir/hello.txt)

  await storage.app.delete();
}
```

## Platforms

| Import | Service | Runs on |
|---|---|---|
| `storage_fs.dart` | `newStorageMemory()`, `newStorageServiceMemory()`, `storageServiceMemory` | everywhere |
| `storage_fs.dart` | `newStorageServiceFs(fileSystem: ..., basePath: ...)` (any fs_shim `FileSystem`) | where the file system runs |
| `storage_fs_io.dart` | `storageServiceIo`, `createStorageServiceIo(basePath: ...)` | Dart VM, Flutter native |

`service.storage(app)` needs a local app (`tekartik_firebase_local`). File
`dir/f.txt` of bucket `b` is stored as `<root>/b/data/dir/f.txt`, its metadata
as `<root>/b/meta/dir/f.txt.json`; `<root>` is `basePath`, or
`<app.localPath>/storage`.

## Pitfalls

* `bucket()` without a name is `_default` here: pass the bucket name when the
  same code runs on a real backend.
* A name with `..` segments (`../x`) is resolved on the file system: it leaves
  the bucket folder. Never store a name you did not check (a user upload
  name) with the io service.
* `getFiles` returns at most `maxResults` (default 1000) files and a
  `nextQuery`, `autoPaginate` is ignored: loop on `nextQuery`.
* `ref('gs://bucket/path').getDownloadUrl()` returns the `file://` url of the
  data file (encoded), even when the file does not exist.
* No security rules, no transactions, one process per io folder.

## Agent skills

`skills/tekartik-firebase-storage-fs-setup` (services, layout, tests).
