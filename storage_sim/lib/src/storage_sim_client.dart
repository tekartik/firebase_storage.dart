import 'dart:async';
import 'dart:typed_data';

import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_client.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_storage_sim/src/storage_sim_message.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_server_service.dart';

// ignore: implementation_imports

import 'import_storage.dart'; // ignore: implementation_imports

/// Storage service simulation.
class StorageServiceSim
    with FirebaseProductServiceMixin<Storage>, StorageServiceMixin
    implements StorageService {
  @override
  Storage storage(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppSim, 'app not compatible');
      return _StorageSim(this, app as AppSim);
    });
  }

  //TODO
  /// Delete the app.
  Future deleteApp(App app) async {}
}

StorageServiceSim? _storageServiceSim;

/// Storage service simulation.
StorageServiceSim get storageServiceSim =>
    _storageServiceSim ??= StorageServiceSim();

class _FileMetadataSim with FileMetadataMixin implements FileMetadata {
  @override
  final DateTime dateUpdated;

  @override
  final String md5Hash;

  @override
  final int size;

  @override
  final String? contentType;

  @override
  final String? cacheControl;

  _FileMetadataSim({
    required this.dateUpdated,
    required this.md5Hash,
    required this.size,
    required this.contentType,
    required this.cacheControl,
  });
}

class _FileSim with FileMixin implements File {
  final _BucketSim bucketSim;
  _FileMetadataSim? metadataSim;
  Future<FirebaseSimAppClient> get simClient => bucketSim.simClient;
  @override
  final String name;

  _FileSim(this.bucketSim, this.name, this.metadataSim);

  /// Only set for a listed file (like the other implementations).
  @override
  _FileMetadataSim? get metadata => metadataSim;

  @override
  Bucket get bucket => bucketSim;

  @override
  Future<bool> exists() async {
    var simClient = await bucketSim.simClient;
    var fileData = FileExistsRequestData()
      ..bucket = bucketSim.name
      ..name = name;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodFileExists,
        fileData.toMap(),
      ),
    );

    var responseData = FileExistsResponseData()..fromMap(result);
    return responseData.exists;
  }

  void _fillFileData(FileData fileData) {
    fileData.bucket = bucketSim.name;
    fileData.name = name;
  }

  @override
  Future<void> delete() async {
    var simClient = await this.simClient;
    var requestData = FileDeleteRequestData();
    _fillFileData(requestData);

    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodFileDelete,
      requestData.toMap(),
    );
  }

  @override
  Future<FileMetadata> getMetadata() async {
    var simClient = await this.simClient;
    var requestData = FileGetMetadataRequestData();
    _fillFileData(requestData);

    var result = await simClient.sendRequest<Map>(
      StorageSimServerService.serviceName,
      methodFileGetMetadata,
      requestData.toMap(),
    );

    var responseData = BucketGetFileMetadataResponseData()..fromMap(result);
    return _FileMetadataSim(
      dateUpdated: responseData.dateUpdated,
      size: responseData.size,
      md5Hash: responseData.md5Hash,
      contentType: responseData.contentType,
      cacheControl: responseData.cacheControl,
    );
  }

  @override
  Future<Uint8List> download() async {
    var simClient = await bucketSim.simClient;
    var fileData = FileDownloadRequestData();
    _fillFileData(fileData);

    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodFileDownload,
        fileData.toMap(),
      ),
    );

    var responseData = FileDownloadResponseData()..fromMap(result);
    return asUint8List(responseData.data);
  }

  @override
  Future<void> upload(
    Uint8List bytes, {
    StorageUploadFileOptions? options,
  }) async {
    var simClient = await this.simClient;
    var requestData = FileUploadRequestData()
      ..bucket = bucketSim.name
      ..name = name
      ..data = bytes
      ..contentType = options?.contentType
      ..cacheControl = options?.cacheControl;

    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodFileUpload,
      requestData.toMap(),
    );
  }
}

class _BucketSim with BucketMixin implements Bucket {
  final _StorageSim storageSim;
  Future<FirebaseSimAppClient> get simClient => storageSim.simClient;
  @override
  final String name;

  _BucketSim(this.storageSim, this.name);

  @override
  File file(String path) {
    return _FileSim(this, path, null);
  }

  void _fillBucketData(BucketData bucketData) {
    bucketData.bucket = name;
  }

  @override
  Future<void> create() async {
    var simClient = await this.simClient;
    var bucketData = BucketData()..bucket = name;

    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodBucketCreate,
      bucketData.toMap(),
    );
  }

  @override
  Future<bool> exists() async {
    var simClient = await this.simClient;
    var bucketData = BucketData()..bucket = name;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodBucketExists,
        bucketData.toMap(),
      ),
    );

    var responseData = BucketExistsResponseData()..fromMap(result);
    return responseData.exists;
  }

  @override
  /// List files
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) async {
    var simClient = await this.simClient;
    var requestData = BucketGetFilesRequestData()
      ..prefix = options?.prefix
      ..maxResults = options?.maxResults
      ..autoPaginate = options?.autoPaginate ?? true
      ..pageToken = options?.pageToken;
    _fillBucketData(requestData);

    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodBucketGetFiles,
        requestData.toMap(),
      ),
    );

    var responseData = BucketGetFilesResponseData()..fromMap(result);
    return GetFilesResponse(
      files: responseData.files
          .map(
            (file) => _FileSim(
              this,
              file.name,
              _FileMetadataSim(
                contentType: file.contentType,
                cacheControl: file.cacheControl,
                dateUpdated: file.dateUpdated,
                md5Hash: file.md5Hash,
                size: file.size,
              ),
            ),
          )
          .toList(),
      nextQuery: responseData.nextPageToken == null
          ? null
          : GetFilesOptions(
              prefix: options?.prefix,
              maxResults: options?.maxResults,
              pageToken: responseData.nextPageToken,
              autoPaginate: options?.autoPaginate ?? true,
            ),
    );
  }
}

class _StorageSim extends Object
    with FirebaseAppProductMixin<Storage>, FirebaseStorageMixin
    implements FirebaseStorage {
  _StorageSim(this.storageServiceSim, this.appSim);

  final StorageServiceSim storageServiceSim;
  final FirebaseAppSim appSim;

  Future<FirebaseSimAppClient> get simClient => appSim.simAppClient;

  @override
  Bucket bucket([String? name]) {
    return _BucketSim(
      this,
      name ?? appSim.options.storageBucket ?? 'sim.bucket',
    );
  }

  @override
  String toString() => 'StorageSim[${identityHashCode(this)}]';

  @override
  StorageService get service => storageServiceSim;

  @override
  FirebaseApp get app => appSim;
}
