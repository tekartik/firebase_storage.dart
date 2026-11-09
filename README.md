# firebase_storage.dart

Platform neutral Cloud Storage (Firebase Storage) API for Dart and Flutter,
and its local implementations. Write the storage code once against
`tekartik_firebase_storage`, run it on Flutter, REST, node, the admin SDK, the
file system or in memory.

## Packages

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_storage` | [storage](storage) | the API (buckets, files, metadata, listing, links); start here |
| `tekartik_firebase_storage_fs` | [storage_fs](storage_fs) | file system backend: in memory (`newStorageMemory()` for tests) or io |
| `tekartik_firebase_storage_sim` | [storage_sim](storage_sim) | client and server of a remote simulation (web socket) |
| `tekartik_firebase_storage_test` | [storage_test](storage_test) | the shared tests every backend runs |

The Flutter, REST, node and admin SDK backends are in their own repos
(`firebase_flutter`, `firebase_rest.dart`, `firebase_node.dart`,
`firebase_admin_sdk.dart`, under `https://github.com/tekartik/`).

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage
```

See the [storage package README](storage/README.md) for a first program, the
backends and the common pitfalls.
