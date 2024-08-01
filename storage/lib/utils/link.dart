import 'package:path/path.dart';

/// A reference to a file in a storage bucket
class StorageFileRef {
  /// The bucket name
  late final String bucket;

  /// The path in the bucket
  late final String path;

  /// Create a new [StorageFileRef] with the given [bucket] and [path]
  StorageFileRef(this.bucket, this.path);

  /// Create a new [StorageFileRef] from a [uri]
  StorageFileRef.fromLink(Uri uri) {
    var parts = uri.pathSegments;
    bucket = uri.host;
    path = url.joinAll(parts);
  }

  /// Create a uri
  Uri toLink() {
    return Uri.parse(url.join('gs://$bucket/$path'));
  }

  @override
  String toString() => toLink().toString();
}
