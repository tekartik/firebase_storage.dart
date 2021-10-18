import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:fs_shim/fs.dart' as fs_shim;
import 'package:fs_shim/fs_io.dart' as fs;
import 'package:fs_shim/fs_memory.dart' as fs;
import 'package:fs_shim/fs_shim.dart' as fs;
import 'package:fs_shim/utils/path.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/date_time_utils.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';

import 'import.dart';

class StorageServiceFs implements StorageService {
  final fs.FileSystem fileSystem;
  final _storages = <App, StorageFs>{};
  final String? basePath;

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

StorageServiceFs? _storageServiceMemory;

StorageServiceFs get storageServiceFsMemory =>
    _storageServiceMemory ??= StorageServiceFs(fs.newFileSystemMemory());

StorageServiceFs newStorageServiceFsMemory() =>
    StorageServiceFs(fs.newFileSystemMemory());

StorageServiceFs? _storageServiceIo;

StorageServiceFs get storageServiceFsIo =>
    _storageServiceIo ??= StorageServiceFs(fs.fileSystemIo);

class FileFs with FileMixin implements File {
  @override
  final BucketFs bucket;
  final String path;

  String get dataPath => bucket.getFsFileDataPath(path);

  String get metaPath => bucket.getFsFileMetaPath(path);

  fs_shim.File get fsFile => bucket.fs.file(dataPath);

  fs_shim.File get fsMetaFile => bucket.fs.file(metaPath);

  FileFs({required this.bucket, required this.path, this.metadata});

  @override
  final FileMetadataFs? metadata;

  @override
  Future save(content) async {
    if (content is String) {
      await writeAsString(content);
    } else {
      await writeAsBytes(content as Uint8List?);
    }
  }

  Future<FileMetadataFs> writeFileMeta(Uint8List? bytes) async {
    Future<FileMetadataFs> _writeMeta() async {
      var md5Hash = md5.convert(bytes!).toString();
      var size = bytes.length;
      var dateUpdated = DateTime.now().toUtc();
      var metadata = FileMetadataFs(
          md5Hash: md5Hash, dateUpdated: dateUpdated, size: size);
      // Write meta
      await fsMetaFile.writeAsString(jsonEncode(metadata.toMap()));
      return metadata;
    }

    try {
      return await _writeMeta();
    } catch (_) {
      try {
        await fsMetaFile.parent.create(recursive: true);
      } catch (_) {}
      // try again
      return await _writeMeta();
    }
  }

  @override
  Future<void> writeAsBytes(Uint8List? bytes) async {
    Future _writeData() async {
      // Write data
      await fsFile.writeAsBytes(bytes!);
    }

    try {
      await _writeData();
    } catch (_) {
      try {
        await fsFile.parent.create(recursive: true);
      } catch (_) {}
      try {
        await fsMetaFile.parent.create(recursive: true);
      } catch (_) {}
      // try again
      await _writeData();
    }

    await writeFileMeta(bytes);
  }

  @override
  Future<Uint8List> download() => readAsBytes();

  @override
  Future<Uint8List> readAsBytes() async {
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

  String get dataPath => fs.path.join(localPath!, 'data');

  String get metaPath => fs.path.join(localPath!, 'meta');
  String? localPath;

  BucketFs(this.storage, String? name) : name = name ?? '_default' {
    if (storage.service.basePath != null) {
      localPath = fs.path.join(storage.service.basePath!, this.name);
    } else {
      localPath = fs.path.join(
          toContextPath(fs.path, storage.app.localPath), 'storage', this.name);
    }
  }

  @override
  FileFs file(String path) => FileFs(bucket: this, path: path);

  @override
  Future<bool> exists() async {
    return await storage.service.fileSystem.directory(localPath!).exists();
  }

  fs_shim.FileSystem get fs => storage.service.fileSystem;

  String _fixFsName(String name) {
    if (name.startsWith('/')) {
      name = name.substring(1);
    }
    return toContextPath(fs.path, name);
  }

  String getFsFileDataPath(String? name) =>
      name == null ? dataPath : fs.path.join(dataPath, _fixFsName(name));

  String getFsFileMetaPath(String? name) => name == null
      ? metaPath
      : fs.path.join(metaPath, '${_fixFsName(name)}.json');

  Future<FileMetadataFs> getOrGenerateMeta(String name) async {
    // TODO handle directories
    try {
      return FileMetadataFs.fromMap(
          jsonDecode(await fs.file(getFsFileMetaPath(name)).readAsString())
              as Map);
    } catch (e) {
      print('Generating missing meta');
      var file = this.file(name);
      var bytes = await file.readAsBytes();
      return await file.writeFileMeta(bytes);
    }
  }

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) async {
    var bucketDataPath = dataPath;
    var parentDataPath = getFsFileDataPath(options?.prefix);
    List<fs_shim.FileSystemEntity> files;
    try {
      files = await fs.directory(parentDataPath).list(recursive: true).toList();
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

    // Handle windows case to convert to url.
    String _toStoragePath(String path) =>
        toPosixPath(fs.path.relative(path, from: bucketDataPath));

    // marker?
    // TODO too slow for now
    if (options?.pageToken != null) {
      int? startIndex;
      for (var i = 0; i < paths.length; i++) {
        if (options!.pageToken!.compareTo(_toStoragePath(paths[i])) <= 0) {
          startIndex = i;
        }
      }
      if (startIndex != null) {
        paths = paths.sublist(startIndex);
      }
    }

    // limit?
    var maxResults = options?.maxResults ?? 1000;
    String? nextMarker;
    if (paths.length > maxResults) {
      // set next marker
      nextMarker = _toStoragePath(paths[maxResults]);

      paths = paths.sublist(0, maxResults);
    }

    // Convert
    var storageFiles = <File>[];
    for (var path in paths) {
      var name = _toStoragePath(path);
      var metadata = await getOrGenerateMeta(name);
      storageFiles.add(FileFs(bucket: this, path: name, metadata: metadata));
    }

    return GetFilesResponseFs(
        storageFiles,
        nextMarker == null
            ? null
            : GetFilesOptions(
                maxResults: options!.maxResults,
                prefix: options.prefix,
                pageToken: nextMarker,
                autoPaginate: options.autoPaginate));
  }
}

class StorageFs with StorageMixin implements Storage {
  final StorageServiceFs service;
  final AppLocal app;

  StorageFs(this.service, this.app);

  @override
  BucketFs bucket([String? name]) {
    return BucketFs(this, name);
  }

  @override
  ReferenceFs ref([String? path]) {
    return ReferenceFs(this, path);
  }
}

class ReferenceFs with ReferenceMixin {
  final StorageFs storage;
  final String? path;

  ReferenceFs(this.storage, this.path);

  @override
  Future<String> getDownloadUrl() async {
    var refLink = StorageFileRef.fromLink(Uri.parse(path!));
    var uri =
        'file://${url.join(toPosixPath(storage.service.fileSystem.path.absolute(storage.bucket(refLink.bucket).dataPath)), refLink.path)}';
    return uri;
  }
}

class GetFilesResponseFs implements GetFilesResponse {
  @override
  final List<File> files;

  @override
  final GetFilesOptions? nextQuery;

  GetFilesResponseFs(this.files, this.nextQuery);

  @override
  String toString() => {
        'files': files,
        if (nextQuery != null) 'nextQuery': nextQuery
      }.toString();
}

class FileMetadataFs implements FileMetadata {
  @override
  final String md5Hash;

  @override
  final DateTime dateUpdated;

  @override
  final int size;

  Map<String, Object?> toMap() => {
        'md5Hash': md5Hash,
        'dateUpdated': dateUpdated.toUtc().toIso8601String(),
        'size': size
      };

  FileMetadataFs(
      {required this.md5Hash, required this.dateUpdated, required this.size});

  factory FileMetadataFs.fromMap(Map map) {
    var md5Hash = mapStringValue(map, 'md5Hash')!;
    var dateUpdated = anyToDateTime(mapStringValue(map, 'dateUpdated'))!;
    var size = mapIntValue(map, 'size')!;
    return FileMetadataFs(
        md5Hash: md5Hash, dateUpdated: dateUpdated, size: size);
  }
}
