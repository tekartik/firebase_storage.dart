@JS()
library tekartik_firebase_node.storage_binding;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:node_interop/node_interop.dart';

// https://googleapis.dev/nodejs/storage/latest/
import 'package:tekartik_common_utils/common_utils_import.dart';

@JS()
@anonymous
class GetFilesOptions {
  external int get maxResults;

  external String get prefix;

  external String get pageToken;

  external bool get autoPaginate;

  external factory GetFilesOptions(
      {int maxResults, String prefix, bool autoPaginate, String pageToken});
}

// File meta data in GetFiles
// Simple file:
// {kind: storage#object, id: xxxxx.appspot.com/tests/yyyyyyy/simple_file.txt/1606218107753072,
// selfLink: https://www.googleapis.com/storage/v1/b/xxxxx.appspot.com/o/tests%2Fyyyyyyy%2Fsimple_file.txt,
// mediaLink: https://storage.googleapis.com/download/storage/v1/b/xxxxx.appspot.com/o/tests%2Fyyyyyyy%2Fsimple_file.txt?generation=1606218107753072&alt=media,
// name: tests/yyyyyyy/simple_file.txt,
// bucket: xxxxx.appspot.com, generation: 1606218107753072,
// metageneration: 1, contentType: text/plain, storageClass: STANDARD, size: 40,
// md5Hash: 9iamz8697RUaZ/je/alxAg==, crc32c: RCAaIg==, etag: CPCk+t2Mm+0CEAE=, timeCreated: 2020-11-24T11:41:47.752Z,
// updated: 2020-11-24T11:41:47.752Z, timeStorageClassUpdated: 2020-11-24T11:41:47.752Z}
// Simple folder:
// {kind: storage#object, id: xxxxx.appspot.com/apps//1580594626021569,
// selfLink: https://www.googleapis.com/storage/v1/b/xxxxx.appspot.com/o/apps%2F,
// mediaLink: https://storage.googleapis.com/download/storage/v1/b/xxxxx.appspot.com/o/apps%2F?generation=1580594626021569&alt=media,
// name: apps/, bucket: xxxxx.appspot.com, generation: 1580594626021569, metageneration: 1,
// contentType: application/x-www-form-urlencoded;charset=UTF-8, storageClass:
// STANDARD, size: 0, md5Hash: 1B2M2Y8AsgTpgAmY7PhCfg==, contentDisposition: inline; filename*=utf-8''apps,
// crc32c: AAAAAA==, etag: CMGR3+mtsecCEAE=, timeCreated: 2020-02-01T22:03:46.021Z, updated: 2020-02-01T22:03:46.021Z,
// timeStorageClassUpdated: 2020-02-01T22:03:46.021Z, metadata: {firebaseStorageDownloadTokens: 3712857b-088d-4ed5-8604-7b084ac0e76e}}
@JS()
@anonymous
abstract class FileMetadata {
  external String get md5Hash;

  external String get size;

  external String get updated;
}

@JS()
@anonymous
abstract class File {
  external Promise save(dynamic data);

  external Promise exists();

  external Promise download();

  external Promise delete();

  /// The name of the remote file.
  external String get name;

  /// The bucket instance the is attached to.
  external Bucket get bucket;

  /// The metadata (when read through GetFiles)
  ///
  /// Null for object that are 'folder' like (trailing /)
  external FileMetadata get metadata;
}

/*
@JS()
@anonymous
abstract class FileInfo {
  external String get name;
  external String get md5Hash;
  external String get timeCreated;
  external int get size;
}
*/
@JS()
@anonymous
abstract class Bucket {
  external String get name;

  external void set(String name);

  external File file(String path);

  external Promise exists();

  /// Get [File] objects for the files currently in the bucket.
  external Promise getFiles([GetFilesOptions options]);
}

class GetFilesResponse {
  final List<File> files;
  final GetFilesOptions nextQuery;

  GetFilesResponse(this.files, this.nextQuery);
}

Future<GetFilesResponse> bucketGetFiles(Bucket bucket,
    [GetFilesOptions options]) async {
  var response = (await promiseToFuture(bucket.getFiles(options))) as List;
  // devPrint(response);
  // The reponse is an array!

  var files = (response[0] as List).cast<File>().toList();

  /*
  if (false) {
    for (var file in files) {
      devPrint('file: ${file.name}');
      devPrint('bucket: ${file.bucket.name}');
      devPrint('metadata: ${jsObjectToDebugString(file.metadata)}');
      for (var key in jsObjectKeys(file)) {}
      // devPrint('files: ${jsObjectToDebugString(file)}');
    }
  }
   */

  GetFilesOptions nextQuery;
  if (response.length > 1) {
    // The second object is the whole query!

    nextQuery = response[1] as GetFilesOptions;
  }

  /// response is an array with first item being an array.
  return GetFilesResponse(files, nextQuery);
}

@JS()
@anonymous
abstract class Storage {
  external Bucket bucket([String name]);
}

@JS()
@anonymous
abstract class StorageApp {
  external Storage storage();
}

@JS()
@anonymous
class Error {
  dynamic errors;
  dynamic code;
  String message;
}
