import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';

/// Options for [Bucket.getFiles], used to page through and filter the list
/// of files stored in a [Bucket].
///
/// This abstraction allows configuring options for retrieving lists of files,
/// such as pagination and filtering by prefix, similar to Firebase Storage's
/// list API.
class GetFilesOptions {
  /// The maximum number of files to return for this request.
  ///
  /// `null` (the default) means no limit is requested and the backend's
  /// default page size is used.
  final int? maxResults;

  /// Restricts results to files whose name starts with this prefix.
  ///
  /// `null` (the default) means no prefix filtering is applied and all
  /// files in the bucket are eligible.
  final String? prefix;

  /// Whether to automatically follow [GetFilesResponse.nextQuery] and fetch
  /// every page of results until the listing is exhausted.
  ///
  /// Defaults to `true`. Set to `false` to only retrieve a single page and
  /// handle pagination manually using [GetFilesResponse.nextQuery].
  final bool autoPaginate;

  /// The token identifying the page of results to retrieve, typically taken
  /// from a previous [GetFilesResponse.nextQuery].
  ///
  /// `null` (the default) means the first page is requested.
  final String? pageToken;

  /// Creates options for listing files with [Bucket.getFiles].
  ///
  /// [maxResults], [prefix] and [pageToken] are unset by default (`null`),
  /// meaning no limit, no prefix filter and the first page respectively.
  /// [autoPaginate] defaults to `true`.
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

  /// Returns a copy of these options, replacing any field for which a
  /// non-`null` argument is given.
  ///
  /// [maxResults], [prefix], [autoPaginate] and [pageToken] each override
  /// the corresponding field when provided; omitted (or `null`) arguments
  /// keep the current value of this instance.
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

/// The result of a [Bucket.getFiles] call.
///
/// Provides an abstraction over Firebase Storage's list results, including
/// the list of files returned and, if more results are available, the
/// options to fetch the next page.
abstract class GetFilesResponse {
  /// The files returned for this page of the listing.
  ///
  /// Empty if the bucket (or the requested prefix) contains no files.
  List<File> get files;

  /// The options to pass to [Bucket.getFiles] to retrieve the next page of
  /// results.
  ///
  /// `null` when there are no more results to fetch.
  GetFilesOptions? get nextQuery;

  /// Creates a [GetFilesResponse] wrapping the given [files] and, optionally,
  /// [nextQuery] to continue pagination.
  ///
  /// [nextQuery] is `null` when there is no further page to fetch.
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

/// Alias for [FirebaseStorageMixin], kept for backward compatibility.
///
/// Prefer [FirebaseStorageMixin] directly; this typedef may be deprecated in
/// the future.
typedef StorageMixin = FirebaseStorageMixin;

/// Mixin providing default [Storage] member implementations.
///
/// Every member throws [UnimplementedError] by default. Concrete
/// implementations are expected to mix this in and override the members
/// they support, so future additions to [Storage] do not break existing
/// implementations.
mixin FirebaseStorageMixin implements Storage {
  /// See [FirebaseStorage.bucket]. Throws [UnimplementedError] unless
  /// overridden.
  @override
  Bucket bucket([String? name]) {
    throw UnimplementedError('$runtimeType.bucket($name)');
  }

  /// See [FirebaseStorage.ref]. Throws [UnimplementedError] unless
  /// overridden.
  @override
  Reference ref([String? path]) {
    throw UnimplementedError('$runtimeType.ref($path)');
  }
}

/// Alias for [FirebaseStorage], kept for backward compatibility.
///
/// Prefer [FirebaseStorage] directly; this typedef may be deprecated in the
/// future.
typedef Storage = FirebaseStorage;

/// Options controlling how a file is uploaded via [File.upload].
///
/// This abstraction configures upload parameters, such as content type,
/// mirroring Firebase Storage's upload options.
class StorageUploadFileOptions {
  /// The MIME content type to associate with the uploaded file (e.g.
  /// `'text/plain'`, `'image/png'`).
  ///
  /// `null` (the default) means no explicit content type is set and the
  /// backend/implementation determines its own default (which may be
  /// inferred from the file name or left unset).
  final String? contentType;

  /// The `Cache-Control` value served with the file (e.g.
  /// `'public, max-age=31536000, immutable'` for a file that never changes,
  /// `'no-cache'` for a small file revalidated on each read).
  ///
  /// `null` (the default) means no explicit cache control is set and the
  /// backend default applies.
  final String? cacheControl;

  /// Creates upload options. [contentType] and [cacheControl] are `null` by
  /// default, meaning they are not sent.
  StorageUploadFileOptions({this.contentType, this.cacheControl});
}

/// The entrypoint for Firebase Storage operations.
///
/// This abstraction provides access to cloud storage buckets and references,
/// enabling file uploads, downloads, and management, inspired by Firebase
/// Storage's API.
abstract class FirebaseStorage implements FirebaseAppProduct<FirebaseStorage> {
  /// Returns the [Bucket] with the given [name].
  ///
  /// If [name] is `null` or omitted, the implementation's default bucket is
  /// returned (typically derived from the app's configuration, see
  /// [appOptionsGetStorageBucket]).
  Bucket bucket([String? name]);

  /// Returns a new [Reference].
  ///
  /// If the [path] is empty, the reference will point to the root of the
  /// storage bucket.
  ///
  /// Not all implementation supports that.
  Reference ref([String? path]);

  /// The [FirebaseStorage] instance for the default [FirebaseApp].
  ///
  /// Throws if no default [FirebaseApp] exists or if no storage product is
  /// registered for it.
  static FirebaseStorage get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<FirebaseStorage>()!;

  /// The [FirebaseStorageService] that created this instance.
  FirebaseStorageService get service;
}

/// Represents a bucket in cloud storage.
///
/// An abstraction over Firebase Storage buckets, allowing operations like
/// creating, checking existence, and listing files within the bucket.
abstract class Bucket {
  /// The name of this bucket.
  String get name;

  /// Returns a reference to the [File] at [path] within this bucket.
  ///
  /// This does not perform any network operation nor guarantee that the
  /// file exists; use [File.exists] to check.
  File file(String path);

  /// Returns whether this bucket currently exists in cloud storage.
  Future<bool> exists();

  /// Creates this bucket if it does not already exist.
  ///
  /// Completes once the bucket has been created (or confirmed to already
  /// exist, depending on the implementation).
  Future<void> create();

  /// Lists files in this bucket.
  ///
  /// [options] controls pagination and prefix filtering; when omitted (or
  /// `null`), the default [GetFilesOptions] are used (no prefix filter,
  /// automatic pagination enabled).
  ///
  /// Returns a [GetFilesResponse] whose [GetFilesResponse.files] is empty
  /// when the bucket (or the requested prefix) contains no files.
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]);
}

/// Mixin providing default [Bucket] member implementations.
///
/// Every member throws [UnimplementedError] by default. Concrete
/// implementations are expected to mix this in and override the members
/// they support, so future additions to [Bucket] do not break existing
/// implementations.
mixin BucketMixin implements Bucket {
  /// See [Bucket.getFiles]. Throws [UnimplementedError] unless overridden.
  @override
  Future<GetFilesResponse> getFiles([GetFilesOptions? options]) {
    throw UnimplementedError('$runtimeType.getFiles');
  }

  /// See [Bucket.exists]. Throws [UnimplementedError] unless overridden.
  @override
  Future<bool> exists() {
    throw UnimplementedError('$runtimeType.exists');
  }

  /// See [Bucket.file]. Throws [UnimplementedError] unless overridden.
  @override
  File file(String path) {
    throw UnimplementedError('$runtimeType.file($path)');
  }

  /// See [Bucket.create]. Throws [UnimplementedError] unless overridden.
  @override
  Future<void> create() {
    throw UnimplementedError('$runtimeType.create()');
  }

  /// See [Bucket.name]. Throws [UnimplementedError] unless overridden.
  @override
  String get name => throw UnimplementedError('$runtimeType.name');
}

/// Represents a file in cloud storage.
///
/// An abstraction for Firebase Storage files, supporting operations like
/// uploading, downloading, deleting, and retrieving metadata. Unrelated to
/// `dart:io`'s `File`.
abstract class File {
  /// Uploads [bytes] as the content of this file, creating it if it does
  /// not exist or overwriting it otherwise.
  ///
  /// [options] controls upload parameters such as content type; when
  /// omitted (or `null`), the implementation's default is used.
  ///
  /// Completes once the upload has finished.
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options});

  /// Writes [bytes] as the content of this file, creating it if it does not
  /// exist or overwriting it otherwise.
  ///
  /// Equivalent to calling [upload] without upload options.
  Future<void> writeAsBytes(Uint8List bytes);

  /// Writes [text], UTF-8 encoded, as the content of this file, creating it
  /// if it does not exist or overwriting it otherwise.
  Future<void> writeAsString(String text);

  /// Saves [content] as the content of this file.
  ///
  /// [content] must be either a `String` (written with [writeAsString]) or
  /// a `List<int>` (written with [writeAsBytes]); any other type throws an
  /// [ArgumentError].
  @Deprecated('Use writeAsBytes or writeAsString')
  Future<void> save(/* String | List<int> */ dynamic content);

  /// Returns whether this file currently exists in its [bucket].
  Future<bool> exists();

  /// Downloads and returns the full content of this file as bytes.
  @Deprecated('Use readAsBytes or readAsString')
  Future<Uint8List> download();

  /// Reads and returns the full content of this file as bytes.
  Future<Uint8List> readAsBytes();

  /// Reads the full content of this file and decodes it as UTF-8 text.
  Future<String> readAsString();

  /// Deletes this file from its [bucket].
  ///
  /// Completes once the file has been deleted.
  Future<void> delete();

  /// The name (path) of this file within its [bucket].
  String get name;

  /// The [Bucket] this file belongs to.
  Bucket get bucket;

  /// Cached metadata for this file, if available.
  ///
  /// Populated when the file was obtained through [Bucket.getFiles]; `null`
  /// otherwise, or on implementations (such as Flutter) that do not expose
  /// it this way. Use [getMetadata] to fetch it explicitly.
  FileMetadata? get metadata;

  /// Fetches and returns up-to-date [FileMetadata] for this file.
  Future<FileMetadata> getMetadata();
}

/// Metadata associated with a file in cloud storage.
///
/// This abstraction provides details like size, update date, and content
/// type, similar to Firebase Storage's file metadata.
abstract class FileMetadata {
  /// The size of the file, in bytes.
  int get size;

  /// The date and time the file was last updated.
  DateTime get dateUpdated;

  /// The MD5 hash of the file content, as a hex or base64 string depending
  /// on the implementation.
  String get md5Hash;

  /// The MIME content type of the file.
  ///
  /// `null` when the backend has no content type recorded for the file.
  String? get contentType;

  /// The `Cache-Control` value of the file, see
  /// [StorageUploadFileOptions.cacheControl].
  ///
  /// `null` when the file has no cache control recorded.
  String? get cacheControl;
}

/// Mixin providing default [FileMetadata] member implementations.
///
/// Every getter throws [UnimplementedError] by default. Concrete
/// implementations are expected to mix this in and override the getters
/// they support, so future additions to [FileMetadata] do not break
/// existing implementations.
mixin FileMetadataMixin implements FileMetadata {
  /// See [FileMetadata.dateUpdated]. Throws [UnimplementedError] unless
  /// overridden.
  @override
  DateTime get dateUpdated => throw UnimplementedError();

  /// See [FileMetadata.md5Hash]. Throws [UnimplementedError] unless
  /// overridden.
  @override
  String get md5Hash => throw UnimplementedError();

  /// See [FileMetadata.size]. Throws [UnimplementedError] unless overridden.
  @override
  int get size => throw UnimplementedError();

  /// See [FileMetadata.contentType]. Throws [UnimplementedError] unless
  /// overridden.
  @override
  String? get contentType => throw UnimplementedError();

  /// See [FileMetadata.cacheControl]. Returns `null` (no cache control)
  /// unless overridden.
  @override
  String? get cacheControl => null;

  /// Returns a small map-based string representation for debugging,
  /// listing [size], [dateUpdated], [md5Hash] and, when set, [contentType]
  /// and [cacheControl].
  @override
  String toString() => {
    'size': size,
    'dateUpdated': dateUpdated,
    'md5Hash': md5Hash,
    if (contentType != null) 'contentType': contentType,
    if (cacheControl != null) 'cacheControl': cacheControl,
  }.toString();
}

/// Mixin providing default [File] member implementations built on top of
/// [upload] and [download].
///
/// [writeAsBytes], [writeAsString], [readAsBytes], [readAsString] and the
/// deprecated [save] are implemented in terms of [upload] and [download],
/// so overriding those two is often enough to get a fully working [File].
/// All other members throw [UnimplementedError] until overridden.
mixin FileMixin implements File {
  /// See [File.upload]. Throws [UnimplementedError] unless overridden.
  @override
  Future<void> upload(Uint8List bytes, {StorageUploadFileOptions? options}) {
    throw UnimplementedError('$runtimeType.upload()');
  }

  Uint8List _asUint8List(List<int> data) =>
      data is Uint8List ? data : Uint8List.fromList(data);

  /// See [File.writeAsBytes]. Delegates to [upload].
  @override
  Future<void> writeAsBytes(Uint8List bytes) => upload(bytes);

  /// See [File.writeAsString]. Encodes [text] as UTF-8 and delegates to
  /// [writeAsBytes].
  @override
  Future<void> writeAsString(String text) =>
      writeAsBytes(_asUint8List(utf8.encode(text)));

  /// See [File.readAsBytes]. Delegates to [download].
  @override
  Future<Uint8List> readAsBytes() => download();

  /// See [File.readAsString]. Decodes the bytes from [readAsBytes] as
  /// UTF-8.
  @override
  Future<String> readAsString() async => utf8.decode(await readAsBytes());

  /// See [File.getMetadata]. Throws [UnimplementedError] unless overridden.
  @override
  Future<FileMetadata> getMetadata() async =>
      throw UnimplementedError('$runtimeType.getMetadata');
  // To implement
  /// See [File.bucket]. Throws [UnimplementedError] unless overridden.
  @override
  Bucket get bucket => throw UnimplementedError('bucket');

  /// See [File.delete]. Throws [UnimplementedError] unless overridden.
  @override
  Future delete() {
    throw UnimplementedError('$runtimeType.delete');
  }

  // To deprecate
  /// Default implementation of the deprecated `download` member of [File].
  /// Throws [UnimplementedError] unless overridden.
  @override
  Future<Uint8List> download() {
    throw UnimplementedError('$runtimeType.download()');
  }

  /// See [File.exists]. Throws [UnimplementedError] unless overridden.
  @override
  Future<bool> exists() {
    throw UnimplementedError('$runtimeType.exists');
  }

  /// See [File.metadata]. Throws [UnimplementedError] unless overridden.
  @override
  FileMetadata? get metadata =>
      throw UnimplementedError('$runtimeType.metadata');

  /// See [File.name]. Throws [UnimplementedError] unless overridden.
  @override
  String get name => throw UnimplementedError('name');

  // To deprecate
  /// Default implementation of the deprecated `save` member of [File].
  /// Delegates to [writeAsString] for `String` content and [writeAsBytes]
  /// for `List<int>` content. Throws [ArgumentError] for any other
  /// [content] type.
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

/// Alias for [FirebaseStorageService], kept for backward compatibility.
///
/// Prefer [FirebaseStorageService] directly; this typedef may be deprecated
/// in the future.
typedef StorageService = FirebaseStorageService;

/// Firebase storage service abstraction.
///
/// Provides an abstraction for obtaining storage instances from Firebase
/// apps, enabling integration with cloud storage services. Implementations
/// are typically singletons shared between every [App] that uses them.
abstract class FirebaseStorageService {
  /// Returns the [FirebaseStorage] product for [app], creating it on first
  /// access for that app if needed.
  FirebaseStorage storage(App app);
}

/// Represents a reference to a file or directory in cloud storage.
///
/// An abstraction for Firebase Storage references, allowing actions like
/// generating download URLs.
abstract class Reference {
  /// Fetches a long lived download URL for this object.
  ///
  /// Completes with the URL, or throws if this reference does not point to
  /// an existing object.
  Future<String> getDownloadUrl();
}

/// Mixin providing default [Reference] member implementations.
///
/// Every member throws [UnimplementedError] by default. Concrete
/// implementations are expected to mix this in and override the members
/// they support, so future additions to [Reference] do not break existing
/// implementations.
mixin ReferenceMixin implements Reference {
  /// See [Reference.getDownloadUrl]. Throws [UnimplementedError] unless
  /// overridden.
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

/// Extension exposing the Firebase Storage [Storage] product on a
/// [FirebaseApp].
extension TekartikFirebaseStorageFirebaseAppExt on FirebaseApp {
  /// Returns the [Storage] product registered for this app.
  ///
  /// Throws a [StateError] if no storage product is registered for this
  /// app (typically meaning the storage plugin/implementation was not
  /// initialized for it).
  Storage storage() {
    var storage = getProduct<Storage>();
    if (storage == null) {
      throw StateError('No storage product for app $name');
    } else {
      return storage;
    }
  }
}
