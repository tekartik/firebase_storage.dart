import 'dart:async';
import 'dart:typed_data';
import 'package:js/js_util.dart';
import 'package:node_interop/util.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage_node/src/storage_bindings.dart'
    as native;
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_node/impl/firebase_node.dart';

class StorageServiceNode implements StorageService {
  final _storages = <AppNode, StorageNode>{};

  StorageServiceNode();

  @override
  Storage storage(App app) {
    assert(app is AppNode, 'invalid firebase app type ${app.runtimeType}');
    final appNode = app as AppNode;
    var storage = _storages[appNode];
    if (storage == null) {
      // ignore: invalid_use_of_protected_member
      var storageApp = (appNode.nativeInstance).nativeInstance;
      storage = StorageNode((storageApp as native.StorageApp).storage());
      _storages[appNode] = storage;
    }
    return storage;
  }
}

StorageServiceNode _storageServiceNode;
StorageServiceNode get storageServiceNode =>
    _storageServiceNode ??= StorageServiceNode();

class StorageNode implements Storage {
  final native.Storage nativeInstance;

  StorageNode(this.nativeInstance);

  @override
  Bucket bucket([String name]) {
    native.Bucket nativeBucket;
    if (name == null) {
      nativeBucket = callMethod(nativeInstance, 'bucket', []) as native.Bucket;
    } else {
      nativeBucket = nativeInstance.bucket(name);
    }
    return _wrapBucket(nativeBucket);
  }
}

class FileNode with FileMixin implements File {
  final native.File nativeInstance;

  FileNode(this.nativeInstance);

  @override
  Future save(data) => promiseToFuture(nativeInstance.save(data));

  @override
  Future<bool> exists() async {
    // Array with first bool as the response
    var fileExistsResponse =
        (await promiseToFuture(nativeInstance.exists())) as List;
    return fileExistsResponse[0] as bool;
  }

  @override
  Future<Uint8List> download() async {
    // Array with first item as the response
    var downloadResponse =
        (await promiseToFuture(nativeInstance.download())) as List;
    return downloadResponse[0] as Uint8List;
  }

  @override
  Future delete() => promiseToFuture(nativeInstance.delete());

  @override
  String toString() => 'FileNode($name)';

  @override
  String get name => nativeInstance.name;

  @override
  Bucket get bucket => BucketNode(nativeInstance.bucket);
}

class BucketNode implements Bucket {
  final native.Bucket nativeInstance;

  BucketNode(this.nativeInstance);

  @override
  File file(String path) => _wrapFile(nativeInstance.file(path));

  @override
  Future<bool> exists() =>
      promiseToFuture(nativeInstance.exists()).then((data) => data[0] as bool);

  @override
  String get name => nativeInstance.name;

  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions options]) async {
    var nativeResponse = await native.bucketGetFiles(
        nativeInstance, _unwrapGetFilesOptions(options));
    return GetFilesResponseNode(nativeResponse);
  }
}

class GetFilesResponseNode implements GetFilesResponse {
  final native.GetFilesResponse nativeInstance;

  GetFilesResponseNode(this.nativeInstance);

  @override
  List<File> get files => nativeInstance.files.map((e) => FileNode(e)).toList();

  @override
  GetFilesOptions get nextQuery =>
      _wrapGetFilesOptions(nativeInstance.nextQuery);

  @override
  String toString() => {
        'files': files,
        if (nextQuery != null) 'nextQuery': nextQuery
      }.toString();
}

BucketNode _wrapBucket(native.Bucket nativeInstance) =>
    nativeInstance != null ? BucketNode(nativeInstance) : null;

FileNode _wrapFile(native.File nativeInstance) =>
    nativeInstance != null ? FileNode(nativeInstance) : null;

native.GetFilesOptions _unwrapGetFilesOptions(GetFilesOptions options) {
  if (options == null) {
    return null;
  }
  return native.GetFilesOptions(
    maxResults: options.maxResults,
    prefix: options.prefix,
    autoPaginate: options.autoPaginate,
    pageToken: options.pageToken,
  );
}

GetFilesOptions _wrapGetFilesOptions(native.GetFilesOptions options) {
  if (options == null) {
    return null;
  }
  return GetFilesOptions(
      maxResults: options.maxResults,
      prefix: options.prefix,
      autoPaginate: options.autoPaginate,
      pageToken: options.pageToken);
}
