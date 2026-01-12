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
    _storageServiceSim ?? StorageServiceSim();

class _FileMetadataSim with FileMetadataMixin implements FileMetadata {
  @override
  final DateTime dateUpdated;

  @override
  final String md5Hash;

  @override
  final int size;

  @override
  final String? contentType;

  _FileMetadataSim({
    required this.dateUpdated,
    required this.md5Hash,
    required this.size,
    required this.contentType,
  });
}

class _FileSim with FileMixin implements File {
  final _BucketSim bucketSim;
  _FileMetadataSim? metadataSim;
  Future<FirebaseSimAppClient> get simClient => bucketSim.simClient;
  @override
  final String name;

  _FileSim(this.bucketSim, this.name, this.metadataSim);

  @override
  _FileMetadataSim get metadata => metadataSim!;

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
      ..contentType = options?.contentType;

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

  //final transactionLock = Lock();

  //StorageSettings? storageSettingsSim;

  // The key is the streamId from the server
  final Map<int, ServerSubscriptionSim> _subscriptions = {};

  Future<FirebaseSimAppClient> get simClient => appSim.simAppClient;

  void addSubscription(ServerSubscriptionSim subscription) {
    _subscriptions[subscription.id!] = subscription;
  }

  @override
  Bucket bucket([String? name]) {
    return _BucketSim(
      this,
      name ?? appSim.options.storageBucket ?? 'sim.bucket',
    );
  } /*
  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(this, path);

  @override
  DocumentReference doc(String path) => DocumentReferenceSim(this, path);
  */

  Future removeSubscription(ServerSubscriptionSim subscription) async {
    _subscriptions.remove(subscription.id);
    await subscription.close();
  }

  Future close() async {
    var subscriptions = _subscriptions.values.toList();
    for (var subscription in subscriptions) {
      await removeSubscription(subscription);
    }
  }

  /*
  DocumentSnapshotSim documentSnapshotFromData(
    StorageDocumentSnapshotData documentSnapshotData,
  ) {
    var dataMap = documentSnapshotData.data;
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, documentSnapshotData.path),
      dataMap != null,
      documentDataFromJsonMap(this, dataMap),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
    /*
    return documentSnapshotFromDataMap(
        documentSnapshotData.path, documentSnapshotData.data);
        */
  }

  // warning no createTime and update time here
  DocumentSnapshotSim documentSnapshotFromDataMap(
    String path,
    Map<String, Object?>? map,
  ) {
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, path),
      map != null,
      documentDataFromJsonMap(this, map),
      createTime: null,
      updateTime: null,
    );
  }

  DocumentSnapshotSim documentSnapshotFromMessageMap(
    String path,
    Map<String, Object?> map,
  ) {
    var documentSnapshotData = DocumentSnapshotData.fromMessageMap(map);
    var data = documentSnapshotData.data;
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, path),
      data != null,
      documentDataFromJsonMap(this, data),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
  }

  @override
  WriteBatch batch() => WriteBatchSim(this);

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) async {
    var simClient = await this.simClient;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodStorageTransaction,
        <String, Object?>{},
      ),
    );

    var responseData = StorageTransactionResponseData()..fromMap(result);
    final transactionSim = TransactionSim(this, responseData.transactionId);
    late T updateResult;
    try {
      updateResult = await updateFunction(transactionSim);
    } catch (_) {
      // Make sure to clean up on cancel
      await transactionSim.cancel();
      rethrow;
    }
    await transactionSim.commit();
    return updateResult;
  }

  Future<DocumentSnapshot> get(StorageGetRequestData requestData) async {
    var simClient = await this.simClient;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodStorageGet,
        requestData.toMap(),
      ),
    );

    var documentSnapshotData = StorageDocumentSnapshotDataImpl()
      ..fromMap(result);
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, documentSnapshotData.path),
      documentSnapshotData.data != null,
      documentDataFromJsonMap(this, documentSnapshotData.data),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
  }
  */
  @override
  String toString() => 'StorageSim[${identityHashCode(this)}]';

  @override
  StorageService get service => storageServiceSim;

  @override
  FirebaseApp get app => appSim;
}
