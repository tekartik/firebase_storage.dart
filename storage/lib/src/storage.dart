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

  // Copy options
  GetFilesOptions copyWith({
    int? maxResults,
    String? prefix,
    bool? autoPaginate,
    String? pageToken,
  }) {
    return GetFilesOptions(
      maxResults: maxResults ?? this.maxResults,
      prefix: prefix ?? this.prefix,
      autoPaginate: autoPaginate ?? this.autoPaginate,
      pageToken: pageToken ?? this.pageToken,
    );
  }
}

/// GetFiles response
abstract class GetFilesResponse {
  List<File> get files;

  GetFilesOptions? get nextQuery;

  /// Default implementation
  factory GetFilesResponse(
      {required List<File> files, GetFilesOptions? nextQuery}) {
    return _GetFilesResponse(files: files, nextQuery: nextQuery);
  }
}

class _GetFilesResponse implements GetFilesResponse {
  @override
  final List<File> files;

  @override
  final GetFilesOptions? nextQuery;

  _GetFilesResponse({required this.files, required this.nextQuery});

  @override
  String toString() => {
        'files': files.length,
        if (nextQuery != null) 'nextQuery': nextQuery
      }.toString();
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
  ///
  /// Not all implementation supports that.
  Reference ref([String? path]);
}

abstract class Bucket {
  String get name;

  File file(String path);

  Future<bool> exists();

  Future<void> create();

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
  Future<void> create() {
    throw UnimplementedError();
  }

  @override
  String get name => throw UnimplementedError('name');
}

abstract class File {
  Future<void> writeAsBytes(Uint8List bytes);

  Future<void> writeAsString(String text);

  @Deprecated('Use writeAsBytes or writeAsString')
  Future<void> save(/* String | List<int> */ dynamic content);

  Future<bool> exists();

  @Deprecated('Use readAsBytes or readAsString')
  Future<Uint8List> download();

  Future<Uint8List> readAsBytes();

  Future<String> readAsString();

  Future<void> delete();

  /// Name of the remote file
  String get name;

  /// The bucket instance the is attached to.
  Bucket get bucket;

  /// Available when listed through getFiles (not on flutter though...)
  FileMetadata? get metadata;

  /// Read meatada
  Future<FileMetadata> getMetadata();
}

abstract class FileMetadata {
  int get size;

  DateTime get dateUpdated;

  String get md5Hash;
}

mixin FileMetadataMixin implements FileMetadata {
  @override
  DateTime get dateUpdated => throw UnimplementedError();

  @override
  String get md5Hash => throw UnimplementedError();

  @override
  int get size => throw UnimplementedError();
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

  @override
  Future<FileMetadata> getMetadata() async =>
      throw UnimplementedError('getMetadata');
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
  Future<void> save(dynamic content) {
    if (content is String) {
      return writeAsString(content);
    } else if (content is List<int>) {
      return writeAsBytes(_asUint8List(content));
    } else {
      throw ArgumentError('content must be a String or a List<int>');
    }
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

/// Storage exception type
enum StorageExceptionType { notFound, other }

/// Storage exception
class StorageException implements Exception {
  final StorageExceptionType type;
  final String message;

  StorageException(this.type, this.message);
  @override
  String toString() => 'StorageException($type) $message';
}
