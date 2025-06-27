import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// Query object for listing files.
class GetFilesOptions {
  /// Maximum number of results to return.
  final int? maxResults;

  /// Filter results to files with this prefix.
  final String? prefix;

  /// Whether to automatically paginate through results.
  final bool autoPaginate;

  /// Token to retrieve the next page of results.
  final String? pageToken;

  /// Default implementation
  GetFilesOptions({
    this.maxResults,
    this.prefix,
    this.pageToken,
    this.autoPaginate = true,
  });

  @override
  String toString() => {
    if (maxResults != null) 'maxResults': maxResults,
    if (prefix != null) 'prefix': prefix,
    'autoPaginate': autoPaginate,
    if (pageToken != null) 'pageToken': pageToken,
  }.toString();

  /// Copy options
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
  /// List of files
  List<File> get files;

  /// Next query
  GetFilesOptions? get nextQuery;

  /// Default implementation
  factory GetFilesResponse({
    required List<File> files,
    GetFilesOptions? nextQuery,
  }) {
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
    if (nextQuery != null) 'nextQuery': nextQuery,
  }.toString();
}

/// Compat
typedef StorageMixin = FirebaseStorageMixin;

/// Storage mixin
mixin FirebaseStorageMixin implements Storage {
  @override
  Bucket bucket([String? name]) {
    throw UnimplementedError();
  }

  @override
  Reference ref([String? path]) {
    throw UnimplementedError();
  }
}

/// Compat
typedef Storage = FirebaseStorage;

/// The entrypoint for firebase [Storage].
abstract class FirebaseStorage implements FirebaseAppProduct<FirebaseStorage> {
  /// Returns the [Bucket] with the given name.
  Bucket bucket([String? name]);

  /// Returns a new [Reference].
  ///
  /// If the [path] is empty, the reference will point to the root of the
  /// storage bucket.
  ///
  /// Not all implementation supports that.
  Reference ref([String? path]);

  /// Default Firebase storage instance.
  static FirebaseStorage get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<FirebaseStorage>()!;

  /// Service access
  FirebaseStorageService get service;
}

/// Represents a reference to a Google Cloud Storage object.
abstract class Bucket {
  /// Name of the bucket
  String get name;

  /// Returns a reference to a [File] object.
  File file(String path);

  /// Returns true if the bucket exists.
  Future<bool> exists();

  /// Create the bucket if it does not exist.
  Future<void> create();

  /// List files
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]);
}

/// Bucket mixin
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

/// Represents a reference to a Google Cloud Storage object.
abstract class File {
  /// Write bytes to the file
  Future<void> writeAsBytes(Uint8List bytes);

  /// Write text to the file
  Future<void> writeAsString(String text);

  @Deprecated('Use writeAsBytes or writeAsString')
  /// Save content to the file
  Future<void> save(/* String | List<int> */ dynamic content);

  /// Returns true if the file exists.
  Future<bool> exists();

  @Deprecated('Use readAsBytes or readAsString')
  /// Download the file
  Future<Uint8List> download();

  /// Read bytes
  Future<Uint8List> readAsBytes();

  /// Read text
  Future<String> readAsString();

  /// Delete the file
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

/// File metadata
abstract class FileMetadata {
  /// Size of the file in bytes
  int get size;

  /// Date the file was last updated
  DateTime get dateUpdated;

  /// MD5 hash of the file
  String get md5Hash;
}

/// File metadata mixin
mixin FileMetadataMixin implements FileMetadata {
  @override
  DateTime get dateUpdated => throw UnimplementedError();

  @override
  String get md5Hash => throw UnimplementedError();

  @override
  int get size => throw UnimplementedError();
}

/// File mixin
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

/// Compat
typedef StorageService = FirebaseStorageService;

/// Firebase storage service
abstract class FirebaseStorageService {
  /// Get the storage app product from the app
  FirebaseStorage storage(App app);
}

/// Represents a reference to a Google Cloud Storage object. Developers can
/// upload, download, and delete objects, as well as get/set object metadata.
abstract class Reference {
  /// Fetches a long lived download URL for this object.
  Future<String> getDownloadUrl();
}

/// Reference mixin
mixin ReferenceMixin implements Reference {
  @override
  Future<String> getDownloadUrl() {
    throw UnimplementedError('getDownloadUrl');
  }
}

/// Storage exception type
enum StorageExceptionType {
  /// Not found
  notFound,

  /// Any other exception
  other,
}

/// Storage exception
class StorageException implements Exception {
  /// Type of the exception
  final StorageExceptionType type;

  /// Message
  final String message;

  /// Default constructor
  StorageException(this.type, this.message);
  @override
  String toString() => 'StorageException($type) $message';
}
