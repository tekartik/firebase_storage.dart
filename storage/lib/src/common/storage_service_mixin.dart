import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';

mixin StorageServiceMixin implements StorageService {
  /// Most implementation need a single instance, keep it in memory!
  static final _instances = <App, Storage>{};

  T getInstance<T extends Storage>(App app, T Function() createIfNotFound) {
    var instance = _instances[app] as T;
    if (instance == null) {
      instance = createIfNotFound();
      _instances[app] = instance;
    }
    return instance;
  }
}

/// Find the default storage bucket.
String appOptionsGetStorageBucket(AppOptions options) {
  var storageBucket =
      (options.storageBucket ?? '${options.projectId}.appspot.com');
  return storageBucket;
}
