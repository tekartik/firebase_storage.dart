import 'package:tekartik_firebase_storage/storage.dart';

/// Storage service mixin providing an abstraction for storage service implementations.
///
/// Allows extending storage services with common functionality.
mixin StorageServiceMixin implements StorageService {}

/// Extracts the default storage bucket from app options.
///
/// This utility function provides an abstraction for determining the bucket name
/// from Firebase app configuration, defaulting to the standard appspot.com format.
String appOptionsGetStorageBucket(AppOptions options) {
  var storageBucket =
      (options.storageBucket ?? '${options.projectId}.appspot.com');
  return storageBucket;
}
