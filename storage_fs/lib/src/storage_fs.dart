import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
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
  final String basePath;

  StorageServiceFs(this.fileSystem, {this.basePath});

  @override
  Storage storage(App app) {
    var storage = _storages[app];
    if (storage == null) {
      storage = StorageFs(this, app as AppLocal);
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

class FileFs implements File {
  @override
  final BucketFs bucket;
  final String path;

  String get localPath => join(bucket.localPath, path);

  io.File get fsFile => io.File(localPath);

  FileFs(this.bucket, this.path);

  @override
  Future save(content) async {
    Future _write() async {
      if (content is String) {
        await fsFile.writeAsString(content);
      } else {
        await fsFile.writeAsBytes(content as List<int>);
      }
    }

    try {
      await _write();
    } catch (_) {
      try {
        await fsFile.parent.create(recursive: true);
      } catch (_) {}
      // try again
      await _write();
    }
  }

  @override
  Future<Uint8List> download() async {
    return await fsFile.readAsBytes();
  }

  @override
  Future<bool> exists() async {
    return fsFile.existsSync();
  }

  @override
  Future delete() async {
    return await fsFile.delete();
  }

  @override
  String get name => path;

  @override
  String toString() => 'FileFs($name)';
}

class BucketFs implements Bucket {
  final StorageFs storage;
  @override
  final String name;

  String localPath;

  BucketFs(this.storage, String name) : name = name ?? '_default' {
    if (storage.service.basePath != null) {
      localPath = join(storage.service.basePath, this.name);
    } else {
      localPath = join(storage.ioApp.localPath, 'storage.${this.name}');
    }
  }

  @override
  File file(String path) => FileFs(this, path);

  @override
  Future<bool> exists() async {
    return await storage.service.fileSystem.directory(localPath).exists();
  }
}

class StorageFs implements Storage {
  final StorageServiceFs service;
  final AppLocal ioApp;

  StorageFs(this.service, this.ioApp);

  @override
  Bucket bucket([String name]) {
    return BucketFs(this, name);
  }
}
