import 'package:path/path.dart';

/// A reference to a file in a cloud storage bucket, expressed as a
/// `gs://<bucket>/<path>` style link.
///
/// This abstraction represents a file location in storage, allowing
/// conversion between URIs and structured references, similar to Firebase
/// Storage's `gs://` URIs.
class StorageFileRef {
  /// The name of the storage bucket this reference points into.
  late final String bucket;

  /// The path of the file within [bucket].
  late final String path;

  /// Creates a reference to the file at [path] within [bucket].
  StorageFileRef(this.bucket, this.path);

  /// Creates a reference by parsing a `gs://<bucket>/<path>` style [uri].
  ///
  /// The URI's host becomes [bucket] and its path segments are joined to
  /// form [path].
  StorageFileRef.fromLink(Uri uri) {
    var parts = uri.pathSegments;
    bucket = uri.host;
    path = url.joinAll(parts);
  }

  /// Builds and returns the `gs://<bucket>/<path>` [Uri] for this reference.
  ///
  /// [path] is encoded (a `#`, a `?` or a `%` in a file name is part of the
  /// path), [StorageFileRef.fromLink] gives it back.
  Uri toLink() {
    if (path.isEmpty) {
      return Uri(scheme: 'gs', host: bucket, path: '/');
    }
    // Each segment is encoded as is: a '%20' in a name is not an escape.
    return Uri(scheme: 'gs', host: bucket, pathSegments: path.split('/'));
  }

  /// Returns the `gs://<bucket>/<path>` string form of this reference, same
  /// as `toLink().toString()`.
  @override
  String toString() => toLink().toString();
}
