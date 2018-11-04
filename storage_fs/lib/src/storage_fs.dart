import 'dart:async';
import 'dart:io' as io;
import 'package:fs_shim/fs.dart' as fs;
import 'package:fs_shim/fs_memory.dart' as fs;
import 'package:fs_shim/fs_io.dart' as fs;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

class StorageServiceFs implements StorageService {
  final fs.FileSystem fileSystem;
  final _storages = <App, StorageFs>{};

  StorageServiceFs(this.fileSystem);
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

StorageServiceFs _storageServiceMemory;
StorageServiceFs get storageServiceFsMemory =>
    _storageServiceMemory ??= StorageServiceFs(fs.newFileSystemMemory());

StorageServiceFs _storageServiceIo;
StorageServiceFs get storageServiceFsIo =>
    _storageServiceIo ??= StorageServiceFs(fs.fileSystemIo);

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
