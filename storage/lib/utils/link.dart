import 'package:path/path.dart';

class StorageFileRef {
  late final String bucket;
  late final String path;

  StorageFileRef(this.bucket, this.path);
  StorageFileRef.fromLink(Uri uri) {
    var parts = url.split(uri.path);
    bucket = uri.host;
    path = url.joinAll(parts.sublist(1));
  }

  Uri toLink() {
    return Uri.parse(url.join('gs://$bucket/$path'));
  }

  @override
  String toString() => toLink().toString();
}
