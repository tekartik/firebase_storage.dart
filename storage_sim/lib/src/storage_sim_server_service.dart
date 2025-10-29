import 'dart:core' hide Error;

import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_common_utils/stream/stream_poller.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_message.dart';

// ignore: implementation_imports

import 'storage_sim_plugin.dart'; // ignore: implementation_imports
// ignore: implementation_imports

class StorageSimServerService extends FirebaseSimServerServiceBase {
  late StorageSimPlugin storageSimPlugin;
  final _appServers = <FirebaseSimServerProjectApp, _StorageSimPluginServer>{};

  static final serviceName = 'firebase_storage';
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

      return super.onAppCall(projectApp, channel, methodCall);
    } catch (e, st) {
      if (isDebug) {
        // ignore: avoid_print
        print('error $st');
        // ignore: avoid_print
        print(st);
      }
      rethrow;
    }
  }
}

class SimSubscription<T> {
  late StreamPoller<T> _poller;

  Future<StreamPollerEvent<T?>> getNext() => _poller.getNext();

  SimSubscription(Stream<T> stream) {
    _poller = StreamPoller<T>(stream);
  }

  // Make sure to cancel the pending completer
  Future cancel() => _poller.cancel();
}

/// One per client/app
class _StorageSimPluginServer {
  final StorageSimPlugin storageSimServer;

  /// Implementation
  final Storage storage;
  int lastTransactionId = 0;
  int lastSubscriptionId = 0;

  //Lock? get transactionLock => storageSimServer.transactionLock(storage);
  final transactionLock = Lock();

  //final rpc.Server rpcServer;
  final Map<int, SimSubscription> subscriptions = <int, SimSubscription>{};

  int get newSubscriptionId => ++lastSubscriptionId;

  /*
  DocumentReference requestDocumentReference(Map<String, Object?> params) {
    var storagePathData = StoragePathData()..fromMap(params);
    var ref = storage.doc(storagePathData.path);
    return ref;
  }*/

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
      options: StorageUploadFileOptions(contentType: requestData.contentType),
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
            ..contentType = file.metadata!.contentType,
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
      ..contentType = result.contentType;

    return responseData.toMap();
  }
}

/*
  Future handleStorageSetRequest(Map<String, Object?> params) async {
    var storageSetData = StorageSetData()..fromMap(params);
    var documentData = documentDataFromJsonMap(storage, storageSetData.data);
    SetOptions? options;
    if (storageSetData.merge != null) {
      options = SetOptions(merge: storageSetData.merge);
    }

    await transactionLock.synchronized(() async {
      await storage
          .doc(storageSetData.path)
          .set(documentData!.asMap(), options);
    });
  }

  Future handleStorageUpdateRequest(Map<String, Object?> params) async {
    var storageSetData = StorageSetData()..fromMap(params);
    var documentData = documentDataFromJsonMap(storage, storageSetData.data);

    await transactionLock.synchronized(() async {
      await storage.doc(storageSetData.path).update(documentData!.asMap());
    });
  }

  Future handleStorageDeleteRequest(Map<String, Object?> params) async {
    var storageDeleteData = StoragePathData()..fromMap(params);

    await transactionLock.synchronized(() async {
      await storage.doc(storageDeleteData.path).delete();
    });
  }

  Future handleStorageGetListen(Map<String, Object?> params) async {
    var subscriptionId = newSubscriptionId;
    final path = params[paramPath] as String?;
    return await transactionLock.synchronized(() async {
      var ref = storage.doc(path!);

      subscriptions[subscriptionId] = SimSubscription<DocumentSnapshot>(
        ref.onSnapshot(),
      );
      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleStorageGetCancel(Map<String, Object?> params) async {
    var subscriptionId = params[paramSubscriptionId] as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleStorageGetStream(Map<String, Object?> params) async {
    // New stream?
    var subscriptionId = params[paramSubscriptionId] as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<DocumentSnapshot>?;
    var event = (await subscription?.getNext());
    var map = <String, Object?>{};
    if (event == null || event.done) {
      map[paramDone] = true;
    } else {
      map[paramSnapshot] = DocumentSnapshotData.fromSnapshot(
        event.data!,
      ).toMap();
    }
    return map;
  }

  Future handleStorageQuery(Map<String, Object?> params) async {
    var queryData = StorageQueryData()..storageFromMap(storage, params);
    final query = await getQuery(queryData);

    return await transactionLock.synchronized(() async {
      var querySnapshot = await query.get();

      var data = StorageQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (final doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      return data.toMap();
    });
  }

  Future handleStorageQueryListen(Map<String, Object?> params) async {
    var subscriptionId = newSubscriptionId;
    var queryData = StorageQueryData()..storageFromMap(storage, params);
    return await transactionLock.synchronized(() async {
      final query = await getQuery(queryData);

      subscriptions[subscriptionId] = SimSubscription<QuerySnapshot>(
        query.onSnapshot(),
      );

      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleStorageQueryCancel(Map<String, Object?> params) async {
    var subscriptionId = params[paramSubscriptionId] as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleStorageQueryStream(Map<String, Object?> params) async {
    // New stream?
    var subscriptionId = params[paramSubscriptionId] as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<QuerySnapshot>?;
    try {
      var event = (await subscription?.getNext());
      var map = <String, Object?>{};
      if (event == null || event.done) {
        map[paramDone] = true; // event.done;
        return map;
      }
      final querySnapshot = event.data!;
      var data = StorageQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (final doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      // Changes
      data.changes = <DocumentChangeData>[];
      for (var change in querySnapshot.documentChanges) {
        var documentChangeData = DocumentChangeData()
          ..id = change.document.ref.id
          ..type = documentChangeTypeToString(change.type)
          ..newIndex = change.newIndex
          ..oldIndex = change.oldIndex;
        // need data?
        var path = change.document.ref.path;

        bool findDocByPath() {
          for (var doc in querySnapshot.docs) {
            if (doc.ref.path == path) {
              return true;
            }
          }
          return false;
        }

        if (!findDocByPath()) {
          documentChangeData.data = documentDataToJsonMap(
            documentDataFromSnapshot(change.document),
          );
        }
        data.changes!.add(documentChangeData);
      }
      map[paramSnapshot] = data.toMap();
      return map;
    } catch (_) {}
  }

  Future<Query> getQuery(StorageQueryData queryData) async {
    var collectionPath = queryData.path;
    // Handle param
    var queryInfo = queryData.queryInfo;
    return await applyQueryInfo(storage, collectionPath, queryInfo);
  }

  // Batch
  Future handleStorageBatch(Map<String, Object?> params) async {
    var batchData = StorageBatchData()..storageFromMap(storage, params);

    await transactionLock.synchronized(() async {
      await _handleStorageBatch(batchData);
    });
  }

  Future _handleStorageBatch(StorageBatchData batchData) async {
    var batch = storage.batch();
    for (var item in batchData.operations) {
      if (item is BatchOperationDeleteData) {
        batch.delete(storage.doc(item.path!));
      } else if (item is BatchOperationSetData) {
        batch.set(
          storage.doc(item.path!),
          documentDataFromJsonMap(storage, item.data)!.asMap(),
          item.merge != null ? SetOptions(merge: item.merge) : null,
        );
      } else if (item is BatchOperationUpdateData) {
        batch.update(
          storage.doc(item.path!),
          documentDataFromJsonMap(storage, item.data)!.asMap(),
        );
      } else {
        throw 'not supported $item';
      }
    }
    await batch.commit();
  }

  Completer? transactionCompleter;

  // Transaction
  Future handleStorageTransaction(Map<String, Object?>? params) async {
    var responseData = StorageTransactionResponseData()
      ..transactionId = ++lastTransactionId;

    // start locking but don't wait
    unawaited(
      transactionLock.synchronized(() async {
        transactionCompleter = Completer();
        await transactionCompleter!.future;
        transactionCompleter = null;
      }),
    );
    return responseData.toMap();
  }

  Future handleStorageTransactionCommit(Map<String, Object?> params) async {
    var batchData = StorageBatchData()..storageFromMap(storage, params);

    if (batchData.transactionId == lastTransactionId) {
      try {
        await _handleStorageBatch(batchData);
      } finally {
        // terminate transaction
        transactionCompleter!.complete();
      }
    } else {
      await transactionLock.synchronized(() async {
        await _handleStorageBatch(batchData);
      });
    }
  }

  Future handleStorageTransactionCancel(Map<String, Object?> params) async {
    var requestData = StorageTransactionCancelRequestData()..fromMap(params);

    if (requestData.transactionId == lastTransactionId) {
      // terminate transaction
      transactionCompleter!.complete();
    }
  }*/
