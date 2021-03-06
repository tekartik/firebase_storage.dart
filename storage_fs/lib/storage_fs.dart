import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart' as impl;

/// A global in memory service
StorageService get storageServiceMemory => impl.storageServiceFsMemory;

/// Create an empty in memory service (mainly for unit tests)
StorageService newStorageServiceMemory() => impl.newStorageServiceFsMemory();
