import 'package:tekartik_firebase_storage/storage.dart';

/// Storage service mixin.
mixin StorageServiceMixin implements StorageService {}

/// Find the default storage bucket.
String appOptionsGetStorageBucket(AppOptions options) {
  var storageBucket =
      (options.storageBucket ?? '${options.projectId}.appspot.com');
  return storageBucket;
}
