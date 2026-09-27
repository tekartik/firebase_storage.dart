# Cache control

`StorageUploadFileOptions.cacheControl` stores a `Cache-Control` value with the
uploaded file. `FileMetadata.cacheControl` reads it back (`null` when none was
set).

```dart
await bucket.file('export/export_42.jsonl').upload(
  bytes,
  options: StorageUploadFileOptions(
    contentType: 'application/x-ndjson',
    cacheControl: 'public, max-age=31536000, immutable',
  ),
);
var metadata = await bucket.file('export/export_42.jsonl').getMetadata();
print(metadata.cacheControl); // public, max-age=31536000, immutable
```

## What it changes

Cloud Storage sends the value as the `Cache-Control` header of the file's
downloads, so browsers and CDNs cache the file for as long as it says. Nothing
is sent back to the server while a cached copy is fresh.

- No value: the backend default applies. The Storage emulator sends an empty
  header.
- The value belongs to the upload: uploading the file again without it removes
  it. Pass it on every write of that file.

## Which value

| File | Value | Why |
|---|---|---|
| Never changes, its name changes with its content (`export_<changeId>.jsonl`, hashed or versioned names) | `public, max-age=31536000, immutable` | Cached for a year, never asked again |
| Small, changes in place (`export_meta.json`, a pointer to the current version) | `no-cache` | Cached, but revalidated on each read: a `304` with no body when unchanged |
| Private or per user | `private, no-store` (or none) | Never `public`: a CDN in front could serve it to someone else |

Write the immutable file first and the pointer last, so that a reader never
gets a pointer to a file that is not there yet.

Never use `immutable` on a file that is overwritten under the same name:
browsers keep the old content until `max-age` runs out.

## Per implementation

| Implementation | Upload | `getMetadata()` | Listed files (`getFiles`) | Served header |
|---|---|---|---|---|
| `storage_fs` | stored in the meta file | yes | yes | no server |
| `storage_sim` | sent to the sim server | yes | yes | no server |
| `storage_rest` | object resource `cacheControl` | yes | yes | Cloud Storage |
| `firebase_admin_sdk` | `ObjectMetadata.cacheControl` | yes | yes | Cloud Storage |
| `storage_flutter` | `SettableMetadata.cacheControl` | yes | no listed metadata | Cloud Storage |
| `storage_node` | `save` options `metadata.cacheControl` | yes | yes | Cloud Storage |

The shared test `file_with_cache_control` (package
`tekartik_firebase_storage_test`) checks the upload, the metadata, the listing
and the removal on re-upload. The admin sdk emulator test
(`firebase_admin_sdk_test/test/firebase_storage_admin_sdk_emulator_test.dart`)
also checks the header served by the Storage emulator.
