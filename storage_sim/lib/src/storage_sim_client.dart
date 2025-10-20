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
  Future deleteApp(App app) async {}
}

StorageServiceSim? _storageServiceSim;

StorageServiceSim get storageServiceSim =>
    _storageServiceSim ?? StorageServiceSim();

/*
class DocumentDataSim extends DocumentDataMap {}

class DocumentSnapshotSim
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  @override
  final DocumentReferenceSim ref;

  @override
  final bool exists;

  final DocumentData? documentData;

  DocumentSnapshotSim(
    this.ref,
    this.exists,
    this.documentData, {
    required this.createTime,
    required this.updateTime,
  });

  @override
  Map<String, Object?> get data => documentData!.asMap();

  @override
  final Timestamp? updateTime;

  @override
  final Timestamp? createTime;
}

class DocumentReferenceSim
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin
    implements DocumentReference {
  StorageSim get storageSim => storage as StorageSim;

  DocumentReferenceSim(Storage storage, String path) {
    init(storage, path);
    checkDocumentReferencePath(this.path);
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(storageSim, url.join(this.path, path));

  @override
  Future delete() async {
    var simClient = await storageSim.simClient;
    var storageDeleteData = StoragePathData()..path = path;
    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodStorageDelete,
      storageDeleteData.toMap(),
    );
  }

  @override
  Future<DocumentSnapshot> get() {
    var requestData = StorageGetRequestData()..path = path;
    return storageSim.get(requestData);
  }

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await storageSim.simClient;
    var storageSetData = StorageSetData()
      ..path = path
      ..data = jsonMap
      ..merge = options?.merge;
    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodStorageSet,
      storageSetData.toMap(),
    );
  }

  @override
  Future update(Map<String, Object?> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await storageSim.simClient;
    var storageSetData = StorageSetData()
      ..path = path
      ..data = jsonMap;
    await simClient.sendRequest<void>(
      StorageSimServerService.serviceName,
      methodStorageUpdate,
      storageSetData.toMap(),
    );
  }

  DocumentSnapshotSim documentSnapshotFromDataMap(
    String path,
    Map<String, Object?> map,
  ) => storageSim.documentSnapshotFromDataMap(path, map);

  // do until cancelled
  Future _getStream(
    FirebaseSimClient? simClient,
    String path,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (storageSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(
          await simClient!.sendRequest<Object?>(
            StorageSimServerService.serviceName,
            methodStorageGetStream,
            {paramSubscriptionId: subscriptionId},
          ),
        );
        // devPrint(result);
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }
        subscription.add(
          storageSim.documentSnapshotFromMessageMap(
            path,
            (result[paramSnapshot] as Map).cast<String, dynamic>(),
          ),
        );
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    late ServerSubscriptionSim<DocumentSnapshot> subscription;
    FirebaseSimClient? simClient;
    subscription = ServerSubscriptionSim<DocumentSnapshot>(
      StreamController(
        onCancel: () async {
          await storageSim.removeSubscription(subscription);
          await simClient!.sendRequest<void>(
            StorageSimServerService.serviceName,
            methodStorageGetCancel,
            {paramSubscriptionId: subscription.id},
          );
          await subscription.done;
        },
      ),
    );

    () async {
      simClient = await storageSim.simClient;
      var result = resultAsMap(
        await simClient!.sendRequest<Object>(
          StorageSimServerService.serviceName,
          methodStorageGetListen,
          {paramPath: path},
        ),
      );

      subscription.id = result[paramSubscriptionId] as int?;
      storageSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, path, subscription);
    }();
    return subscription.stream;
  }
}

abstract mixin class QueryMixinSim implements Query {
  AppSim get appSim => storageSim.appSim;

  QueryInfo? get queryInfo;

  CollectionReferenceSim get simCollectionReference;

  StorageSim get storageSim => simCollectionReference.storageSim;

  QuerySim clone() {
    return QuerySim(simCollectionReference)..queryInfo = queryInfo?.clone();
  }

  @override
  Query where(
    String fieldPath, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    bool? isNull,
  }) => clone()
    ..queryInfo!.addWhere(
      WhereInfo(
        fieldPath,
        isEqualTo: isEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        isNull: isNull,
      ),
    );

  void addOrderBy(String key, String directionStr) {
    var orderBy = OrderByInfo(
      fieldPath: key,
      ascending: directionStr != orderByDescending,
    );
    queryInfo!.orderBys.add(orderBy);
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.startAt(snapshot: snapshot, values: values);

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.startAfter(snapshot: snapshot, values: values);

  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.endAt(snapshot: snapshot, values: values);

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.endBefore(snapshot: snapshot, values: values);

  @override
  Query select(List<String> list) {
    return clone()..queryInfo!.selectKeyPaths = list;
  }

  @override
  Query limit(int limit) => clone()..queryInfo!.limit = limit;

  @override
  Query orderBy(String key, {bool? descending}) => clone()
    ..addOrderBy(
      key,
      descending == true ? orderByDescending : orderByAscending,
    );

  DocumentSnapshotSim documentSnapshotFromData(
    DocumentSnapshotData documentSnapshotData,
  ) {
    return storageSim.documentSnapshotFromData(documentSnapshotData);
  }

  @override
  Future<QuerySnapshot> get() async {
    var simClient = await appSim.simClient;
    var data = StorageQueryData()
      ..path = simCollectionReference.path
      ..queryInfo = queryInfo;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        StorageSimServerService.serviceName,
        methodStorageQuery,
        data.toMap(),
      ),
    );

    var querySnapshotData = StorageQuerySnapshotData()..fromMap(result);
    return QuerySnapshotSim(
      querySnapshotData.list
          .map(
            (DocumentSnapshotData documentSnapshotData) =>
                documentSnapshotFromData(documentSnapshotData),
          )
          .toList(),
      <DocumentChangeSim>[],
    );
  }

  // do until cancelled
  Future _getStream(
    FirebaseSimClient? simClient,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (storageSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(
          await simClient!.sendRequest<Map>(
            StorageSimServerService.serviceName,
            methodStorageQueryStream,
            {paramSubscriptionId: subscriptionId},
          ),
        );
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }

        var querySnapshotData = StorageQuerySnapshotData()
          ..fromMap((result[paramSnapshot] as Map).cast<String, dynamic>());

        var docs = querySnapshotData.list
            .map(
              (DocumentSnapshotData documentSnapshotData) =>
                  documentSnapshotFromData(documentSnapshotData),
            )
            .toList();

        var changes = <DocumentChangeSim>[];
        for (var changeData in querySnapshotData.changes!) {
          // snapshot present?
          DocumentSnapshotSim? snapshot;
          if (changeData.data != null) {
            snapshot = storageSim.documentSnapshotFromDataMap(
              url.join(simCollectionReference.path, changeData.id),
              changeData.data,
            );
          } else {
            // find in doc
            snapshot = snapshotsFindById(docs, changeData.id);
          }
          final change = DocumentChangeSim(
            documentChangeTypeFromString(changeData.type!)!,
            snapshot!,
            changeData.newIndex ?? -1, // -1 for removed event
            changeData.oldIndex ?? -1, // -1 for added event
          );
          changes.add(change);
        }
        var snapshot = QuerySnapshotSim(docs, changes);
        subscription.add(snapshot);
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    FirebaseSimClient? simClient;
    late ServerSubscriptionSim<QuerySnapshot> subscription;
    subscription = ServerSubscriptionSim<QuerySnapshot>(
      StreamController(
        onCancel: () async {
          await storageSim.removeSubscription(subscription);
          await simClient!.sendRequest<void>(
            StorageSimServerService.serviceName,
            methodStorageQueryCancel,
            {paramSubscriptionId: subscription.id},
          );
          await subscription.done;
        },
      ),
    );

    () async {
      simClient = await storageSim.simClient;

      var data = StorageQueryData()
        ..path = simCollectionReference.path
        ..queryInfo = queryInfo;

      var result = resultAsMap(
        await simClient!.sendRequest<Map>(
          StorageSimServerService.serviceName,
          methodStorageQueryListen,
          data.toMap(),
        ),
      );

      subscription.id = result[paramSubscriptionId] as int?;
      storageSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, subscription);
    }();
    return subscription.stream;
  }
}

class DocumentChangeSim implements DocumentChange {
  @override
  final DocumentChangeType type;

  @override
  final DocumentSnapshotSim document;

  @override
  final int newIndex;

  @override
  final int oldIndex;

  DocumentChangeSim(this.type, this.document, this.newIndex, this.oldIndex);
}

class QuerySnapshotSim implements QuerySnapshot {
  final List<DocumentSnapshotSim> simDocs;
  final List<DocumentChangeSim> simDocChanges;

  QuerySnapshotSim(this.simDocs, this.simDocChanges);

  @override
  List<DocumentSnapshot> get docs => simDocs;

  // TODO: implement documentChanges
  @override
  List<DocumentChange> get documentChanges => simDocChanges;
}

class QuerySim extends Object
    with QueryDefaultMixin, QueryMixinSim, StorageQueryExecutorMixin
    implements Query {
  @override
  final CollectionReferenceSim simCollectionReference;

  @override
  StorageSim get storageSim => simCollectionReference.storageSim;
  @override
  QueryInfo? queryInfo;

  QuerySim(this.simCollectionReference);

  @override
  Storage get storage => storageSim;
}

class CollectionReferenceSim extends Object
    with
        QueryDefaultMixin,
        QueryMixinSim,
        StorageQueryExecutorMixin,
        CollectionReferenceMixin,
        PathReferenceMixin
    implements CollectionReference {
  @override
  QueryInfo queryInfo = QueryInfo();

  @override
  CollectionReferenceSim get simCollectionReference => this;
  @override
  final StorageSim storageSim;

  @override
  final String path;

  CollectionReferenceSim(this.storageSim, this.path) {
    checkCollectionReferencePath(path);
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await storageSim.simClient;
    var storageSetData = StorageSetData()
      ..path = path
      ..data = jsonMap;
    var result = await simClient.sendRequest<Map>(
      StorageSimServerService.serviceName,
      methodStorageAdd,
      storageSetData.toMap(),
    );
    var storagePathData = StoragePathData()
      ..fromMap(result as Map<String, Object?>);
    return DocumentReferenceSim(storageSim, storagePathData.path);
  }

  @override
  DocumentReference doc([String? path]) =>
      DocumentReferenceSim(storageSim, url.join(this.path, path));

  @override
  String get id => url.basename(path);

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReference) {
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Storage get storage => storageSim;
}
*/

class _FileSim with FileMixin implements File {
  final _BucketSim bucketSim;
  Future<FirebaseSimClient> get simClient => bucketSim.simClient;
  @override
  final String name;

  _FileSim(this.bucketSim, this.name);

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
  Future<FirebaseSimClient> get simClient => storageSim.simClient;
  @override
  final String name;

  _BucketSim(this.storageSim, this.name);

  @override
  File file(String path) {
    return _FileSim(this, path);
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

  Future<FirebaseSimClient> get simClient => appSim.simClient;

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
