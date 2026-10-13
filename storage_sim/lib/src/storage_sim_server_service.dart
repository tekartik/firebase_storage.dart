import 'dart:core' hide Error;

import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_message.dart';

// ignore: implementation_imports

import 'storage_sim_plugin.dart'; // ignore: implementation_imports

// ignore: implementation_imports

/// Storage simulation server service.
class StorageSimServerService extends FirebaseSimServerServiceBase {
  /// Storage simulation plugin.
  late StorageSimPlugin storageSimPlugin;
  final _appServers = <FirebaseSimServerProjectApp, _StorageSimPluginServer>{};

  /// Service name.
  static final serviceName = 'firebase_storage';

  /// Create storage simulation server service.
  StorageSimServerService() : super(serviceName);

  @override
  FutureOr<Object?> onAppCall(
    FirebaseSimServerProjectApp projectApp,
    RpcServerChannel channel,
    RpcMethodCall methodCall,
  ) async {
    try {
      var storageSimPluginServer = _appServers[projectApp] ??= () {
        var app = projectApp.app!;
        var storage = storageSimPlugin.storageService.storage(app);
        //.debugQuickLoggerWrapper();
        // One transaction lock per server
        //storageSimPlugin._locks[storage] ??= Lock();
        return _StorageSimPluginServer(storageSimPlugin, storage);
      }();
      var parameters = methodCall.arguments;
      switch (methodCall.method) {
        case methodBucketExists:
          return await storageSimPluginServer.handleBucketExistsRequest(
            resultAsMap(parameters),
          );
        case methodBucketCreate:
          await storageSimPluginServer.handleBucketCreateRequest(
            resultAsMap(parameters),
          );
          return null;
        case methodBucketGetFiles:
          return await storageSimPluginServer.handleBucketGetFiles(
            resultAsMap(parameters),
          );
        case methodFileExists:
          return await storageSimPluginServer.handleFileExistsRequest(
            resultAsMap(parameters),
          );
        case methodFileUpload:
          await storageSimPluginServer.handleFileUploadRequest(
            resultAsMap(parameters),
          );
          return null;
        case methodFileDownload:
          return await storageSimPluginServer.handleFileDownloadRequest(
            resultAsMap(parameters),
          );
        case methodFileGetMetadata:
          return await storageSimPluginServer.handleFileGetMetadataRequest(
            resultAsMap(parameters),
          );
        case methodFileDelete:
          await storageSimPluginServer.handleFileDeleteRequest(
            resultAsMap(parameters),
          );
          return null;
      }

      return await super.onAppCall(projectApp, channel, methodCall);
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $e');
        // ignore: avoid_print
        print(st);
      }
      rethrow;
    }
  }
}

/// One per client/app
class _StorageSimPluginServer {
  final StorageSimPlugin storageSimServer;

  /// Implementation
  final Storage storage;

  _StorageSimPluginServer(this.storageSimServer, this.storage);

  Future<Model> handleBucketExistsRequest(Model params) async {
    var requestData = BucketExistsRequestData()..fromMap(params);
    var bucketName = requestData.bucket;
    var exists = await storage.bucket(bucketName).exists();
    var response = BucketExistsResponseData()..exists = exists;
    return response.toMap();
  }

  Future<void> handleBucketCreateRequest(Model params) async {
    var requestData = BucketCreateRequestData()..fromMap(params);
    var bucketName = requestData.bucket;
    await storage.bucket(bucketName).create();
  }

  Future<Model> handleFileExistsRequest(Model params) async {
    var requestData = FileExistsRequestData()..fromMap(params);
    var file = _file(requestData);
    var exists = await file.exists();
    var response = FileExistsResponseData()..exists = exists;
    return response.toMap();
  }

  File _file(FileData fileData) {
    return storage.bucket(fileData.bucket).file(fileData.name);
  }

  Future<void> handleFileUploadRequest(Model params) async {
    var requestData = FileUploadRequestData()..fromMap(params);

    var file = _file(requestData);
    await file.upload(
      asUint8List(requestData.data),
      options: StorageUploadFileOptions(
        contentType: requestData.contentType,
        cacheControl: requestData.cacheControl,
      ),
    );
  }

  Future<void> handleFileDeleteRequest(Model params) async {
    var requestData = FileDeleteRequestData()..fromMap(params);

    var file = _file(requestData);
    await file.delete();
  }

  Future<Model> handleFileDownloadRequest(Model params) async {
    var requestData = FileDownloadRequestData()..fromMap(params);

    var file = _file(requestData);
    var data = await file.readAsBytes();
    return (FileDownloadResponseData()..data = data).toMap();
  }

  Future<Model> handleBucketGetFiles(Map<String, Object?> resultAsMap) async {
    var requestData = BucketGetFilesRequestData()..fromMap(resultAsMap);
    var bucket = storage.bucket(requestData.bucket);
    var getFilesResult = await bucket.getFiles(
      GetFilesOptions(
        autoPaginate: requestData.autoPaginate ?? true,
        maxResults: requestData.maxResults,
        pageToken: requestData.pageToken,
        prefix: requestData.prefix,
      ),
    );
    var responseData = BucketGetFilesResponseData();
    responseData.files = getFilesResult.files
        .map(
          (file) => BucketGetFilesFileData()
            ..name = file.name
            ..size = file.metadata!.size
            ..md5Hash = file.metadata!.md5Hash
            ..dateUpdated = file.metadata!.dateUpdated
            ..contentType = file.metadata!.contentType
            ..cacheControl = file.metadata!.cacheControl,
        )
        .toList();
    responseData.nextPageToken = getFilesResult.nextQuery?.pageToken;

    return responseData.toMap();
  }

  Future<Model> handleFileGetMetadataRequest(Map resultAsMap) async {
    var requestData = FileGetMetadataRequestData()..fromMap(resultAsMap);
    var file = _file(requestData);
    var result = await file.getMetadata();
    var responseData = BucketGetFileMetadataResponseData();
    responseData
      ..size = result.size
      ..md5Hash = result.md5Hash
      ..dateUpdated = result.dateUpdated
      ..contentType = result.contentType
      ..cacheControl = result.cacheControl;

    return responseData.toMap();
  }
}
