import 'dart:async';
import 'dart:io' as io;

import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase/firebase_local.dart';


class StorageServiceProviderFs implements StorageServiceProvider {
  @override
  StorageService storageService(Firebase firebase) {
    assert(firebase is FirebaseLocal, 'invalid firebase type');
    return StorageServiceFs(firebase as FirebaseLocal);
  }
}

class StorageServiceFs implements StorageService {
  final FirebaseLocal _firebaseLocal;

  final _storages = <App, StorageFs>{};

  StorageServiceFs(this._firebaseLocal);
  @override
  Storage storage(App app) {
    var storage = _storages[app];
    if (storage == null) {
      storage = StorageFs(app as AppLocal);
      _storages[app] = storage;
    }
    return storage;
  }
  
}
StorageServiceProviderFs _storageServiceProviderFs;
StorageServiceProviderFs get storageServiceProviderFs =>
    _storageServiceProviderFs ?? StorageServiceProviderFs();

StorageServiceProvider get storageServiceProvider => storageServiceProviderFs;
StorageServiceProvider get firebaseStorageServiceProviderFs => storageServiceProviderFs;


class FileIo implements File {
  final BucketIo bucket;
  final String path;

  String get localPath => join(bucket.localPath, path);

  io.File get ioFile => io.File(localPath);

  FileIo(this.bucket, this.path);

  @override
  Future save(content) async {
    _write() async {
      if (content is String) {
        await ioFile.writeAsString(content);
      } else {
        await ioFile.writeAsBytes(content as List<int>);
      }
    }

    try {
      await _write();
    } catch (_) {
      try {
        await ioFile.parent.create(recursive: true);
      } catch (_) {}
      // try again
      await _write();
    }
  }

  @override
  Future<List<int>> download() async {
    return await ioFile.readAsBytes();
  }

  @override
  Future<bool> exists() async {
    return await ioFile.exists();
  }

  @override
  Future delete() async {
    return await ioFile.delete();
  }
}

class BucketIo implements Bucket {
  final StorageFs storage;
  final String name;

  String localPath;

  BucketIo(this.storage, this.name) {
    localPath = join(storage.ioApp.localPath, 'storage.${name ?? '_default'}');
  }

  @override
  File file(String path) => FileIo(this, path);

  @override
  Future<bool> exists() async {
    // TODO: implement exists
    return true;
  }
}

class StorageFs implements Storage {
  final AppLocal ioApp;

  StorageFs(this.ioApp);

  @override
  Bucket bucket([String name]) {
    var bucket = BucketIo(this, name);
    if (name == null && firebaseSembastIoDefaultBucketLocalPath != null) {
      bucket.localPath = firebaseSembastIoDefaultBucketLocalPath;
    }
    return bucket;
  }
}

// Allow overriding the default bucket location
String firebaseSembastIoDefaultBucketLocalPath;
