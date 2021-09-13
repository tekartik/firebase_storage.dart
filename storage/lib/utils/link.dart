import 'package:path/path.dart';

class StorageFileRef {
  late final String bucket;
  late final String name;

  StorageFileRef(this.bucket, this.name);
  StorageFileRef.fromLink(Uri uri) {
    var parts = url.split(uri.path);
    bucket = uri.host;
    name = url.joinAll(parts.sublist(1));
  }

  String toLink() {
    return url.join('gs://$bucket/$name');
  }

  @override
  String toString() => toLink();
}
