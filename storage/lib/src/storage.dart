import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_common_utils/byte_data_utils.dart';

/// Query object for listing files.
class GetFilesOptions {
  final int maxResults;
  final String prefix;
  final bool autoPaginate;
  final String pageToken;

  GetFilesOptions(
      {this.maxResults, this.prefix, this.pageToken, this.autoPaginate = true});

  @override
  String toString() => {
        if (maxResults != null) 'maxResults': maxResults,
        if (prefix != null) 'prefix': prefix,
        'autoPaginate': autoPaginate,
        if (pageToken != null) 'pageToken': pageToken
      }.toString();
}

/// GetFiles response
abstract class GetFilesResponse {
  List<File> get files;
  GetFilesOptions get nextQuery;
}

class StorageMixin {}

abstract class Storage {
  Bucket bucket([String name]);
}

abstract class Bucket {
  String get name;
  File file(String path);
  Future<bool> exists();
  Future<GetFilesResponse> getFiles([GetFilesOptions options]);
}

mixin BucketMixin implements Bucket {
  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions options]) {
    throw UnimplementedError('getFiles');
  }

  @override
  Future<bool> exists() {
    throw UnimplementedError('exists');
  }

  @override
  File file(String path) {
    throw UnimplementedError('file($path)');
  }

  @override
  String get name => throw UnimplementedError('name');
}

abstract class File {
  Future<void> writeAsBytes(Uint8List bytes);
  Future<void> writeAsString(String text);
  Future save(/* String | List<int> */ dynamic content);
  Future<bool> exists();
  Future<Uint8List> download();
  Future<Uint8List> readAsBytes();
  Future<String> readAsString();
  Future delete();

  /// Name of the remote file
  String get name;

  /// The bucket instance the is attached to.
  Bucket get bucket;
}

mixin FileMixin implements File {
  @override
  Future<void> writeAsBytes(Uint8List bytes) => save(bytes);
  @override
  Future<void> writeAsString(String text) =>
      writeAsBytes(asUint8List(utf8.encode(text)));
  @override
  Future<Uint8List> readAsBytes() => download();
  @override
  Future<String> readAsString() async => utf8.decode(await readAsBytes());

  // To implement
  @override
  Bucket get bucket => throw UnimplementedError('bucket');

  @override
  Future delete() {
    throw UnimplementedError('delete');
  }

  @override
  Future<Uint8List> download() {
    throw UnimplementedError('download');
  }

  @override
  Future<bool> exists() {
    throw UnimplementedError('exists');
  }

  @override
  String get name => throw UnimplementedError('name');

  @override
  Future save(content) {
    throw UnimplementedError('save');
  }

}

abstract class StorageService {
  Storage storage(App app);
}
