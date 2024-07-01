import 'package:firebase/firebase.dart' // ignore: deprecated_member_use
    as native;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_browser/src/firebase_browser.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage/storage.dart';

class StorageServiceBrowser
    with FirebaseProductServiceMixin<Storage>
    implements StorageService {
  @override
  Storage storage(App app) {
    return getInstance(app, () {
      assert(app is AppBrowser, 'invalid firebase app type');
      final appBrowser = app as AppBrowser;
      return StorageBrowser(appBrowser.nativeApp.storage());
    });
  }
}

StorageServiceBrowser? _firebaseStorageServiceBrowser;

StorageService get storageService =>
    _firebaseStorageServiceBrowser ??= StorageServiceBrowser();

class StorageBrowser with StorageMixin implements Storage {
  final native.Storage nativeInstance;

  StorageBrowser(this.nativeInstance);

  @override
  Bucket bucket([String? name]) {
    // TODO
    return throw UnimplementedError();
  }
}
