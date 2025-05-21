import 'package:fs_shim/fs.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart' as impl;
export 'package:tekartik_firebase_storage/storage.dart';

/// A global in memory service
StorageService get storageServiceMemory => impl.storageServiceFsMemory;

/// Create an empty in memory service (mainly for unit tests)
StorageService newStorageServiceMemory() => impl.newStorageServiceFsMemory();

/// Quick storage test helper
Storage newStorageMemory() =>
    newStorageServiceMemory().storage(FirebaseLocal().app());

/// New storage service on a file system
StorageService newStorageServiceFs({
  required FileSystem fileSystem,
  String? basePath,
}) => impl.StorageServiceFs(fileSystem, basePath: basePath);
