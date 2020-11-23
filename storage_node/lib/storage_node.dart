import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_node/src/storage_node.dart'
    as storage_node;
export 'package:tekartik_firebase_storage_node/src/storage_node.dart'
    show storageServiceNode, StorageServiceNode, StorageNode, BucketNode;

// Use storageServiceNode instead
@deprecated
StorageService get storageService => storageServiceNode;

/// Get node storage service
StorageService get storageServiceNode => storage_node.storageServiceNode;
