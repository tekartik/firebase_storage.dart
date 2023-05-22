import 'package:path/path.dart';

class StorageFileRef {
  late final String bucket;
  late final String path;

  StorageFileRef(this.bucket, this.path);
  StorageFileRef.fromLink(Uri uri) {
    var parts = uri.pathSegments;
    bucket = uri.host;
    path = url.joinAll(parts);
  }

  Uri toLink() {
    return Uri.parse(url.join('gs://$bucket/$path'));
  }

  @override
  String toString() => toLink().toString();
}
