import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// Query object for listing files in cloud storage.
///
/// This abstraction allows configuring options for retrieving lists of files,
/// such as pagination and filtering by prefix, similar to Firebase Storage's list API.
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

/// Response object for file listing operations.
///
/// Provides an abstraction over Firebase Storage's list results, including
/// the list of files and options for the next page.
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

/// Storage mixin providing an abstraction for Firebase Storage operations.
///
/// Implements core storage functionality, allowing implementations to define
/// how to interact with buckets and references in cloud storage.
mixin FirebaseStorageMixin implements Storage {
  @override
  Bucket bucket([String? name]) {
    throw UnimplementedError('$runtimeType.bucket($name)');
  }

  @override
  Reference ref([String? path]) {
    throw UnimplementedError();
  }
}

/// Compat
typedef Storage = FirebaseStorage;

/// Options for uploading files to cloud storage.
///
/// This abstraction configures upload parameters, such as content type,
/// mirroring Firebase Storage's upload options.
class StorageUploadFileOptions {
  /// Content type
  final String? contentType;

  /// Default constructor
  StorageUploadFileOptions({this.contentType});
}

/// The entrypoint for Firebase Storage operations.
///
/// This abstraction provides access to cloud storage buckets and references,
/// enabling file uploads, downloads, and management, inspired by Firebase Storage's API.
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

/// Represents a bucket in cloud storage.
///
/// An abstraction over Firebase Storage buckets, allowing operations like
/// creating, checking existence, and listing files within the bucket.
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

/// Bucket mixin providing default implementations for bucket operations.
///
/// This abstraction ensures consistent behavior for bucket-related methods
/// across different implementations.
mixin BucketMixin implements Bucket {
  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
    throw UnimplementedError('$runtimeType.getFiles');
  }

  @override
  Future<bool> exists() {
    throw UnimplementedError('$runtimeType.exists');
  }

  @override
  File file(String path) {
    throw UnimplementedError('$runtimeType.file($path)');
  }

  @override
  Future<void> create() {
    throw UnimplementedError('$runtimeType.create()');
  }

  @override
  String get name => throw UnimplementedError('$runtimeType.name');
}

/// Represents a file in cloud storage.
///
/// An abstraction for Firebase Storage files, supporting operations like
/// uploading, downloading, deleting, and retrieving metadata.
abstract class File {
  /// Write bytes to the file
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options});

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

/// Metadata associated with a file in cloud storage.
///
/// This abstraction provides details like size, update date, and content type,
/// similar to Firebase Storage's file metadata.
abstract class FileMetadata {
  /// Size of the file in bytes
  int get size;

  /// Date the file was last updated
  DateTime get dateUpdated;

  /// MD5 hash of the file
  String get md5Hash;

  /// Content type of the file
  String? get contentType;
}

/// File metadata mixin providing default implementations.
///
/// Ensures consistent access to file metadata properties across implementations.
mixin FileMetadataMixin implements FileMetadata {
  @override
  DateTime get dateUpdated => throw UnimplementedError();

  @override
  String get md5Hash => throw UnimplementedError();

  @override
  int get size => throw UnimplementedError();

  @override
  String? get contentType => throw UnimplementedError();

  @override
  String toString() => {
    'size': size,
    'dateUpdated': dateUpdated,
    'md5Hash': md5Hash,
    if (contentType != null) 'contentType': contentType,
  }.toString();
}

/// File mixin providing default implementations for file operations.
///
/// This abstraction handles common file actions like reading, writing, and
/// uploading, with fallbacks for deprecated methods.
mixin FileMixin implements File {
  @override
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options}) {
    throw UnimplementedError('$runtimeType.upload()');
  }

  Uint8List _asUint8List(List<int> data) =>
      data is Uint8List ? data : Uint8List.fromList(data);

  @override
  Future<void> writeAsBytes(Uint8List bytes) => upload(bytes);

  @override
  Future<void> writeAsString(String text) =>
      writeAsBytes(_asUint8List(utf8.encode(text)));

  @override
  Future<Uint8List> readAsBytes() => download();

  @override
  Future<String> readAsString() async => utf8.decode(await readAsBytes());

  @override
  Future<FileMetadata> getMetadata() async =>
      throw UnimplementedError('$runtimeType.getMetadata');
  // To implement
  @override
  Bucket get bucket => throw UnimplementedError('bucket');

  @override
  Future delete() {
    throw UnimplementedError('$runtimeType.delete');
  }

  // To deprecate
  @override
  Future<Uint8List> download() {
    throw UnimplementedError('$runtimeType.download()');
  }

  @override
  Future<bool> exists() {
    throw UnimplementedError('$runtimeType.exists');
  }

  @override
  FileMetadata? get metadata =>
      throw UnimplementedError('$runtimeType.metadata');

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

/// Firebase storage service abstraction.
///
/// Provides an abstraction for obtaining storage instances from Firebase apps,
/// enabling integration with cloud storage services.
abstract class FirebaseStorageService {
  /// Get the storage app product from the app
  FirebaseStorage storage(App app);
}

/// Represents a reference to a file or directory in cloud storage.
///
/// An abstraction for Firebase Storage references, allowing actions like
/// generating download URLs.
abstract class Reference {
  /// Fetches a long lived download URL for this object.
  Future<String> getDownloadUrl();
}

/// Reference mixin providing default implementations.
///
/// Ensures consistent behavior for reference operations across implementations.
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
