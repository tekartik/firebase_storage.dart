import 'package:tekartik_firebase_storage/storage.dart';

/// Mixin providing a base for [FirebaseStorageService] implementations.
///
/// Currently adds no members of its own; implementations mix this in
/// (alongside implementing [FirebaseStorageService]) so that future shared
/// bookkeeping can be added here without breaking them.
mixin FirebaseStorageServiceMixin implements StorageService {}

/// Alias for [FirebaseStorageServiceMixin], kept for backward compatibility.
///
/// Prefer [FirebaseStorageServiceMixin] directly; this typedef may be
/// deprecated in the future.
typedef StorageServiceMixin = FirebaseStorageServiceMixin;

/// Resolves the default Cloud Storage bucket name for the given app
/// [options].
///
/// Returns [AppOptions.storageBucket] when set; otherwise falls back to the
/// standard `'<projectId>.appspot.com'` naming convention built from
/// [AppOptions.projectId].
String appOptionsGetStorageBucket(AppOptions options) {
  var storageBucket =
      (options.storageBucket ?? '${options.projectId}.appspot.com');
  return storageBucket;
}
