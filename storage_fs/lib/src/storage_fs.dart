import 'dart:async';
import 'dart:typed_data';
import 'package:fs_shim/fs.dart' as fs_shim;
import 'package:fs_shim/fs_memory.dart' as fs;
import 'package:fs_shim/fs_io.dart' as fs;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:fs_shim/fs_shim.dart' as fs;
import 'import.dart';

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

class FileFs with FileMixin implements File {
  @override
  final BucketFs bucket;
  final String path;

  String get localPath => join(bucket.localPath, path);

  fs_shim.File get fsFile => bucket.fs.file(localPath);

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
    return fsFile.exists();
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

class BucketFs with BucketMixin implements Bucket {
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

  fs_shim.FileSystem get fs => storage.service.fileSystem;

  String getFsFilePath(String name) =>
      name == null ? localPath : url.join(localPath, name);

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions options]) async {
    var bucketPath = localPath;
    var parentPath = getFsFilePath(options?.prefix);
    List<fs_shim.FileSystemEntity> files;
    try {
      files = await fs.directory(parentPath).list(recursive: true).toList();
    } on fs_shim.FileSystemException catch (_) {
      // Not found?
      files = <fs_shim.FileSystemEntity>[];
    }
    // devPrint(files);

    var paths = <String>[];
    for (var file in files) {
      if (await fs.isFile(file.path)) {
        paths.add(file.path);
      }
    }
    paths.sort();

    String _toStoragePath(String path) =>
        url.normalize(fs.path.relative(path, from: bucketPath));

    // marker?
    // TODO too slow for now
    if (options?.pageToken != null) {
      int startIndex;
      for (var i = 0; i < paths.length; i++) {
        if (options.pageToken.compareTo(_toStoragePath(paths[i])) <= 0) {
          startIndex = i;
        }
      }
      if (startIndex != null) {
        paths = paths.sublist(startIndex);
      }
    }

    // limit?
    var maxResults = options?.maxResults ?? 1000;
    String nextMarker;
    if (paths.length > maxResults) {
      // set next marker
      nextMarker = _toStoragePath(paths[maxResults]);

      paths = paths.sublist(0, maxResults);
    }

    // Convert
    var storageFiles = <File>[];
    for (var path in paths) {
      /*
      var stat = await fs.file(path).stat();
      var size = stat.size;
      var dateModified = stat.modified;
       */
      var name = _toStoragePath(path);
      storageFiles.add(FileFs(this, name));
    }

    return GetFilesResponseFs(
        storageFiles,
        nextMarker == null
            ? null
            : GetFilesOptions(
                maxResults: options.maxResults,
                prefix: options.prefix,
                pageToken: nextMarker,
                autoPaginate: options.autoPaginate));
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

class GetFilesResponseFs implements GetFilesResponse {
  @override
  final List<File> files;

  @override
  final GetFilesOptions nextQuery;

  GetFilesResponseFs(this.files, this.nextQuery);

  @override
  String toString() => {
        'files': files,
        if (nextQuery != null) 'nextQuery': nextQuery
      }.toString();
}
