import 'package:firebase/firebase.dart' as native;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_browser/src/firebase_browser.dart';
import 'package:tekartik_firebase_storage/storage.dart';

class StorageServiceBrowser implements StorageService {
  @override
  Storage storage(App app) {
    assert(app is AppBrowser, 'invalid firebase app type');
    AppBrowser appBrowser = app;
    return StorageBrowser(appBrowser.nativeApp.storage());
  }
}

StorageServiceBrowser _firebaseStorageServiceBrowser;

StorageService get storageService =>
    _firebaseStorageServiceBrowser ??= StorageServiceBrowser();

class StorageBrowser implements Storage {
  final native.Storage nativeInstance;

  StorageBrowser(this.nativeInstance);

  @override
  Bucket bucket([String name]) {
    return null;
  }
}