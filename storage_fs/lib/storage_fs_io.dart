import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_firebase_storage_fs/src/storage_fs.dart' as impl;

import 'package:tekartik_firebase_storage/storage.dart';

StorageService get storageServiceIo => impl.storageServiceFsIo;

StorageService createStorageServiceIo({String? basePath}) =>
    impl.StorageServiceFs(fileSystemIo, basePath: basePath);
