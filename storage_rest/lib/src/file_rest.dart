import 'dart:typed_data';

import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_rest/src/bucket_rest.dart';
import 'package:tekartik_firebase_storage_rest/src/storage_rest_impl.dart';

class FileMetadataRest implements FileMetadata {
  @override
  final DateTime dateUpdated;

  @override
  final String md5Hash;

  @override
  final int size;

  FileMetadataRest({this.dateUpdated, this.md5Hash, this.size});
}

class FileRest with FileMixin implements File {
  final BucketRest bucketRest;
  @override
  final FileMetadata metadata;
  final String path;
  @override
  String get name => path;
  StorageRestImpl get impl => bucketRest.impl;
  FileRest(this.bucketRest, this.path, [this.metadata]);

  @override
  Future<bool> exists() => impl.fileExists(bucketRest, path);

  @override
  Future<void> writeAsBytes(Uint8List bytes) async {
    await impl.writeFile(bucketRest, path, bytes);
  }

  @override
  Future<void> save(content) async {
    if (content is Uint8List) {
      return await writeAsBytes(content);
    } else if (content is String) {
      return await writeAsString(content);
    }
    return await super.save(content);
  }

  @override
  Future<Uint8List> readAsBytes() => impl.readFile(bucketRest, path);
  @override
  Future<Uint8List> download() => readAsBytes();

  @override
  Future<void> delete() => impl.deleteFile(bucketRest, path);
}
