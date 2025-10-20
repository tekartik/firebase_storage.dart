import 'package:cv/cv.dart';

import 'package:tekartik_firebase_sim/firebase_sim_message.dart';

const methodFileExists = 'file/exists';
const methodFileUpload = 'file/upload';
const methodFileDownload = 'file/download';
const methodFileDelete = 'file/delete';
const methodFileGetMetadata = 'file/get_metadata';
const methodBucketExists = 'bucket/exists';
const methodBucketGetFiles = 'bucket/get_files';
const methodBucketCreate = 'bucket/create';
const paramBucket = 'bucket';
const paramName = 'name';

typedef BucketExistsResponseData = CommonExistsResponseData;
typedef FileExistsResponseData = CommonExistsResponseData;

class CommonExistsResponseData extends BaseData {
  late bool exists;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    exists = map['exists'] as bool;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['exists'] = exists;
    return map;
  }
}

class FileDownloadResponseData extends BaseData {
  late List<int> data;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as List).cast<int>();
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    return map;
  }
}

typedef BucketExistsRequestData = BucketData;
typedef FileExistsRequestData = FileData;
typedef FileDeleteRequestData = FileData;
typedef FileGetMetadataRequestData = FileData;
typedef FileDownloadRequestData = FileData;
typedef BucketCreateRequestData = BucketData;

class FileUploadRequestData extends FileData {
  late List<int> data;
  String? contentType;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as List).cast<int>();
    contentType = map['contentType'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (contentType != null) {
      map['contentType'] = contentType;
    }
    return map;
  }
}

class BucketGetFileMetadataResponseData extends BaseData {
  late String? contentType;
  late DateTime dateUpdated;
  late String md5Hash;
  late int size;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    md5Hash = map['md5Hash'] as String;
    contentType = map['contentType'] as String?;
    size = map['size'] as int;
    var dateUpdatedString = map['dateUpdated'] as String;
    dateUpdated = DateTime.parse(dateUpdatedString);
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (contentType != null) {
      map['contentType'] = contentType;
    }

    map['md5Hash'] = md5Hash;

    map['size'] = size;
    map['dateUpdated'] = dateUpdated.toIso8601String();

    return map;
  }
}

class BucketGetFilesFileData extends BaseData {
  late String name;
  late String? contentType;
  late DateTime dateUpdated;
  late String md5Hash;
  late int size;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    name = map['name'] as String;
    md5Hash = map['md5Hash'] as String;
    contentType = map['contentType'] as String?;
    size = map['size'] as int;
    var dateUpdatedString = map['dateUpdated'] as String;
    dateUpdated = DateTime.parse(dateUpdatedString);
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['name'] = name;
    if (contentType != null) {
      map['contentType'] = contentType;
    }

    map['md5Hash'] = md5Hash;

    map['size'] = size;
    map['dateUpdated'] = dateUpdated.toIso8601String();

    return map;
  }
}

class BucketGetFilesResponseData extends BaseData {
  late List<BucketGetFilesFileData> files;
  String? nextPageToken;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    files = (map['files'] as List).cast<Map>().map((item) {
      var fileData = BucketGetFilesFileData();
      fileData.fromMap(item);
      return fileData;
    }).toList();
    nextPageToken = map['nextPageToken'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();

    map['files'] = files.map((file) => file.toMap()).toList();
    if (nextPageToken != null) {
      map['nextPageToken'] = nextPageToken;
    }
    return map;
  }
}

class BucketData extends BaseData {
  late String bucket;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    bucket = map[paramBucket] as String;
  }

  @override
  Model toMap() {
    var map = super.toMap();
    map[paramBucket] = bucket;
    return map;
  }
}

class BucketGetFilesRequestData extends BucketData {
  String? prefix;
  String? pageToken;
  int? maxResults;
  bool? autoPaginate;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    prefix = map['prefix'] as String?;
    pageToken = map['pageToken'] as String?;
    maxResults = map['maxResults'] as int?;
    autoPaginate = map['autoPaginate'] as bool?;
  }

  @override
  Model toMap() {
    var map = super.toMap();
    if (prefix != null) {
      map['prefix'] = prefix;
    }
    if (pageToken != null) {
      map['pageToken'] = pageToken;
    }
    if (maxResults != null) {
      map['maxResults'] = maxResults;
    }
    if (autoPaginate != null) {
      map['autoPaginate'] = autoPaginate;
    }
    return map;
  }
}

class FileData extends BucketData {
  late String name;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    name = map[paramName] as String;
  }

  @override
  Model toMap() {
    var map = super.toMap();
    map[paramName] = name;
    return map;
  }
}

/*
const paramPath = 'path';
const paramSnapshot = 'snapshot'; // map

const methodStorageSet = 'storage/set';
const methodStorageUpdate = 'storage/update';
const methodStorageAdd = 'storage/add';
const methodStorageGet = 'storage/get';
const methodStorageGetListen = 'storage/get/listen'; // first query then next
const methodStorageGetStream = 'storage/get/stream'; // first query then next
const methodStorageGetCancel = 'storage/get/cancel'; // query and notification
const methodStorageDelete = 'storage/delete';
const methodStorageQuery = 'storage/query';
const methodStorageBatch = 'storage/batch';
const methodStorageTransaction = 'storage/transaction';
const methodStorageTransactionCommit =
    'storage/transaction/commit'; // batch data
const methodStorageTransactionCancel =
    'storage/transaction/cancel'; // transactionId
const methodStorageQueryListen =
    'storage/query/listen'; // query from client and notification from server
const methodStorageQueryStream =
    'storage/query/stream'; // query from client and notification from server
const methodStorageQueryCancel = 'storage/query/cancel';

class StoragePathData extends BaseData {
  late String path;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map[paramPath] as String;
  }

  @override
  Model toMap() {
    var map = super.toMap();
    map[paramPath] = path;
    return map;
  }
}

// get/getStream
class StorageGetData extends StoragePathData {}

class StorageDocumentSnapshotDataImpl extends StorageSetData
    implements StorageDocumentSnapshotData {
  @override
  Timestamp? createTime;
  @override
  Timestamp? updateTime;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    createTime = Timestamp.tryAnyAsTimestamp(map['createTime']);
    updateTime = Timestamp.tryAnyAsTimestamp(map['updateTime']);
  }
}

abstract class StorageDocumentSnapshotData {
  String get path;

  Map<String, Object?>? get data;

  Timestamp? get createTime;

  Timestamp? get updateTime;
}

class DocumentGetSnapshotData extends DocumentSnapshotData {
  DocumentGetSnapshotData.fromSnapshot(super.snapshot) : super.fromSnapshot();

  // optional for stream only
  int? streamId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (streamId != null) {
      map['streamId'] = streamId;
    }
    return map;
  }
}

// sub date
class DocumentSnapshotData extends StoragePathData
    implements StorageDocumentSnapshotData {
  @override
  Map<String, Object?>? data;

  @override
  Timestamp? createTime;
  @override
  Timestamp? updateTime;

  DocumentSnapshotData.fromSnapshot(DocumentSnapshot snapshot) {
    path = snapshot.ref.path;
    data = snapshotDataToJsonMap(snapshot);
    createTime = snapshot.createTime;
    updateTime = snapshot.updateTime;
  }

  DocumentSnapshotData.fromMessageMap(Map<String, Object?> map) {
    fromMap(map);
  }

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    createTime = Timestamp.tryAnyAsTimestamp(map['createTime']);
    updateTime = Timestamp.tryAnyAsTimestamp(map['updateTime']);
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    map['createTime'] = createTime?.toIso8601String();
    map['updateTime'] = updateTime?.toIso8601String();
    return map;
  }
}

class DocumentChangeData extends BaseData {
  String? id;
  String? type; // added/modified/removed
  int? newIndex;
  int? oldIndex;
  Map<String, Object?>? data; // only present for deleted

  @override
  void fromMap(Map map) {
    id = map['id'] as String?;
    type = map['type'] as String?;
    newIndex = map['newIndex'] as int?;
    newIndex = map['oldIndex'] as int?;
    data = (map['data'] as Map?)?.cast<String, dynamic>();
  }

  @override
  Map<String, Object?> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'type': type,
      'newIndex': newIndex,
      'oldIndex': oldIndex,
    };
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }
}

class StorageQuerySnapshotData extends BaseData {
  late List<DocumentSnapshotData> list;
  List<DocumentChangeData>? changes;

  // optional for stream only
  int? streamId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    list = [];
    for (var item in map['list'] as List) {
      list.add(
        DocumentSnapshotData.fromMessageMap(
          (item as Map).cast<String, dynamic>(),
        ),
      );
    }
    changes = [];
    for (var item in map['changes'] as List) {
      changes!.add(
        DocumentChangeData()..fromMap((item as Map).cast<String, dynamic>()),
      );
    }
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    var rawList = <Map<String, Object?>>[];
    for (var snapshot in list) {
      rawList.add(snapshot.toMap());
    }
    map['list'] = rawList;

    var rawChanges = <Map<String, Object?>>[];
    if (changes?.isNotEmpty == true) {
      for (var change in changes!) {
        rawChanges.add(change.toMap());
      }
    }
    map['changes'] = rawChanges;

    if (streamId != null) {
      map['streamId'] = streamId;
    }
    return map;
  }
}

class StorageSetData extends StoragePathData {
  Map<String, Object?>? data;
  bool? merge;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    merge = map['merge'] as bool?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (merge != null) {
      map['merge'] = merge;
    }
    return map;
  }
}

class StorageGetRequestData extends StoragePathData {
  int? transactionId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

class AdminInitializeAppData extends BaseData {
  String? projectId;
  String? name;

  @override
  void fromMap(Map map) {
    projectId = map['projectId'] as String?;
    name = map['name'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'projectId': projectId, 'name': name};
    return map;
  }
}

class FirebaseInitializeAppResponseData extends BaseData {
  int? appId;

  @override
  void fromMap(Map map) {
    appId = map['appId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'appId': appId};
    return map;
  }
}

class StorageTransactionResponseData extends BaseData {
  int? transactionId;

  @override
  void fromMap(Map map) {
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'transactionId': transactionId};
    return map;
  }
}

class StorageQueryData extends StoragePathData {
  QueryInfo? queryInfo;

  void storageFromMap(Storage storage, Map<String, Object?> map) {
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(
      storage,
      map['query'] as Map<String, Object?>,
    );
  }

  @override
  @Deprecated('Use storageFromMap')
  void fromMap(Map map) {
    throw 'need storage';
    /*
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(map['query'] as Map<String, Object?>);
    */
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['query'] = queryInfoToJsonMap(queryInfo!);
    return map;
  }
}

class BatchOperationDeleteData extends BatchOperationData {}

class BatchOperationUpdateData extends BatchOperationData {
  Map<String, Object?>? data;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    return map;
  }
}

class BatchOperationSetData extends BatchOperationData {
  Map<String, Object?>? data;
  bool? merge;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    merge = map['merge'] as bool?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (merge != null) {
      map['merge'] = merge;
    }
    return map;
  }
}

abstract class BatchOperationData extends BaseData {
  String? method;
  String? path;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    method = map['method'] as String?;
    path = map['path'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['method'] = method;
    map['path'] = path;
    return map;
  }
}

// for batch and transaction commit
class StorageBatchData extends BaseData {
  int? transactionId;
  List<BatchOperationData> operations = [];

  void storageFromMap(Storage storage, Map<String, Object?> map) {
    super.fromMap(map);
    var list = map['list'] as List;
    transactionId = map['transactionId'] as int?;

    for (var item in list) {
      var itemMap = (item as Map).cast<String, dynamic>();
      var method = itemMap['method'] as String?;
      switch (method) {
        case methodStorageDelete:
          operations.add(BatchOperationDeleteData()..fromMap(itemMap));
          break;
        case methodStorageSet:
          operations.add(BatchOperationSetData()..fromMap(itemMap));
          break;
        case methodStorageUpdate:
          operations.add(BatchOperationUpdateData()..fromMap(itemMap));
          break;
        default:
          throw 'method $method not supported';
      }
    }
  }

  @override
  @Deprecated('Use storageFromMap')
  void fromMap(Map map) {
    throw 'need storage';
    /*
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(map['query'] as Map<String, Object?>);
    */
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    var list = <Map<String, Object?>>[];
    for (var operation in operations) {
      list.add(operation.toMap());
    }
    map['list'] = list;
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

// for batch and transaction commit
class StorageTransactionCancelRequestData extends BaseData {
  int? transactionId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

abstract class StorageQueryStreamIdBase extends BaseData {
  int? streamId;

  @override
  void fromMap(Map map) {
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'streamId': streamId};
    return map;
  }
}

class StorageQueryStreamCancelData extends StorageQueryStreamIdBase {}

class StorageQueryStreamResponse extends StorageQueryStreamIdBase {}

class StorageGetStreamResponse extends StorageQueryStreamResponse {}
*/
