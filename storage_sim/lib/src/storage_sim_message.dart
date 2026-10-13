import 'package:cv/cv.dart';

import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

/// Method file exists.
const methodFileExists = 'file/exists';

/// Method file upload.
const methodFileUpload = 'file/upload';

/// Method file download.
const methodFileDownload = 'file/download';

/// Method file delete.
const methodFileDelete = 'file/delete';

/// Method file get metadata.
const methodFileGetMetadata = 'file/get_metadata';

/// Method bucket exists.
const methodBucketExists = 'bucket/exists';

/// Method bucket get files.
const methodBucketGetFiles = 'bucket/get_files';

/// Method bucket create.
const methodBucketCreate = 'bucket/create';

/// Param bucket.
const paramBucket = 'bucket';

/// Param name.
const paramName = 'name';

/// Bucket exists response data.
typedef BucketExistsResponseData = CommonExistsResponseData;

/// File exists response data.
typedef FileExistsResponseData = CommonExistsResponseData;

/// Common exists response data.
class CommonExistsResponseData extends BaseData {
  /// Exists.
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

/// File download response data.
class FileDownloadResponseData extends BaseData {
  /// Bytes.
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

/// Bucket exists request data.
typedef BucketExistsRequestData = BucketData;

/// File exists request data.
typedef FileExistsRequestData = FileData;

/// File delete request data.
typedef FileDeleteRequestData = FileData;

/// File get metadata request data.
typedef FileGetMetadataRequestData = FileData;

/// File download request data.
typedef FileDownloadRequestData = FileData;

/// Bucket create request data.
typedef BucketCreateRequestData = BucketData;

/// File upload request data.
class FileUploadRequestData extends FileData {
  /// Bytes.
  late List<int> data;

  /// Content type.
  String? contentType;

  /// Cache control.
  String? cacheControl;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as List).cast<int>();
    contentType = map['contentType'] as String?;
    cacheControl = map['cacheControl'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (contentType != null) {
      map['contentType'] = contentType;
    }
    if (cacheControl != null) {
      map['cacheControl'] = cacheControl;
    }
    return map;
  }
}

/// Bucket get file metadata response data.
class BucketGetFileMetadataResponseData extends BaseData {
  /// Content type.
  late String? contentType;

  /// Cache control.
  String? cacheControl;

  /// Date updated.
  late DateTime dateUpdated;

  /// MD5 hash.
  late String md5Hash;

  /// Size.
  late int size;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    md5Hash = map['md5Hash'] as String;
    contentType = map['contentType'] as String?;
    cacheControl = map['cacheControl'] as String?;
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
    if (cacheControl != null) {
      map['cacheControl'] = cacheControl;
    }

    map['md5Hash'] = md5Hash;

    map['size'] = size;
    map['dateUpdated'] = dateUpdated.toIso8601String();

    return map;
  }
}

/// Bucket get files file data.
class BucketGetFilesFileData extends BaseData {
  /// Name.
  late String name;

  /// Content type.
  late String? contentType;

  /// Cache control.
  String? cacheControl;

  /// Date updated.
  late DateTime dateUpdated;

  /// MD5 hash.
  late String md5Hash;

  /// Size.
  late int size;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    name = map['name'] as String;
    md5Hash = map['md5Hash'] as String;
    contentType = map['contentType'] as String?;
    cacheControl = map['cacheControl'] as String?;
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
    if (cacheControl != null) {
      map['cacheControl'] = cacheControl;
    }

    map['md5Hash'] = md5Hash;

    map['size'] = size;
    map['dateUpdated'] = dateUpdated.toIso8601String();

    return map;
  }
}

/// Bucket get files response data.
class BucketGetFilesResponseData extends BaseData {
  /// Files.
  late List<BucketGetFilesFileData> files;

  /// Next page token.
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

/// Bucket data.
class BucketData extends BaseData {
  /// Bucket.
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

/// Bucket get files request data.
class BucketGetFilesRequestData extends BucketData {
  /// Prefix.
  String? prefix;

  /// Page token.
  String? pageToken;

  /// Max results.
  int? maxResults;

  /// Auto paginate.
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

/// File data.
class FileData extends BucketData {
  /// Name.
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
