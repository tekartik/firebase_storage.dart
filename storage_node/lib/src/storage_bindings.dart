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
}

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
