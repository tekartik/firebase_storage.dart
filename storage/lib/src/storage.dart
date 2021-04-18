import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_firebase/firebase.dart';

/// Query object for listing files.
class GetFilesOptions {
  final int? maxResults;
  final String? prefix;
  final bool autoPaginate;
  final String? pageToken;

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

  GetFilesOptions? get nextQuery;
}

mixin StorageMixin implements Storage {
  @override
  Bucket bucket([String? name]) {
    throw UnimplementedError();
  }

  @override
  Reference ref([String? path]) {
    throw UnimplementedError();
  }
}

/// The entrypoint for firebase [Storage].
abstract class Storage {
  Bucket bucket([String? name]);

  /// Returns a new [Reference].
  ///
  /// If the [path] is empty, the reference will point to the root of the
  /// storage bucket.
  Reference ref([String? path]);
}

abstract class Bucket {
  String get name;

  File file(String path);

  Future<bool> exists();

  Future<GetFilesResponse> getFiles([GetFilesOptions? options]);
}

mixin BucketMixin implements Bucket {
  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
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

  Future<void> save(/* String | List<int> */ dynamic content);

  Future<bool> exists();

  Future<Uint8List> download();

  Future<Uint8List> readAsBytes();

  Future<String> readAsString();

  Future<void> delete();

  /// Name of the remote file
  String get name;

  /// The bucket instance the is attached to.
  Bucket get bucket;

  /// Available when listed through getFiles
  FileMetadata? get metadata;
}

abstract class FileMetadata {
  int get size;

  DateTime get dateUpdated;

  String get md5Hash;
}

mixin FileMixin implements File {
  Uint8List _asUint8List(List<int> data) =>
      data is Uint8List ? data : Uint8List.fromList(data);

  @override
  Future<void> writeAsBytes(Uint8List bytes) => save(bytes);

  @override
  Future<void> writeAsString(String text) =>
      writeAsBytes(_asUint8List(utf8.encode(text)));

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

  // To deprecate
  @override
  Future<Uint8List> download() {
    throw UnimplementedError('download');
  }

  @override
  Future<bool> exists() {
    throw UnimplementedError('exists');
  }

  @override
  FileMetadata? get metadata => throw UnimplementedError('metadata');

  @override
  String get name => throw UnimplementedError('name');

  // To deprecate
  @override
  Future<void> save(content) {
    throw UnimplementedError('save');
  }
}

abstract class StorageService {
  Storage storage(App app);
}

/// Represents a reference to a Google Cloud Storage object. Developers can
/// upload, download, and delete objects, as well as get/set object metadata.
abstract class Reference {
  /// Fetches a long lived download URL for this object.
  Future<String> getDownloadUrl();
}

mixin ReferenceMixin implements Reference {
  @override
  Future<String> getDownloadUrl() {
    throw UnimplementedError('getDownloadUrl');
  }
}
