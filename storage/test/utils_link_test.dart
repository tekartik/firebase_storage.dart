import 'package:tekartik_firebase_storage/utils/link.dart';
import 'package:test/test.dart';

void main() {
  group('link', () {
    test('link', () {
      var uri = Uri.parse('gs://test.appspot.com/test/sub.jpg');
      var ref = StorageFileRef.fromLink(uri);
      expect(ref.bucket, 'test.appspot.com');
      expect(ref.path, 'test/sub.jpg');
      expect(ref.toString(), uri.toString());
    });
    test('with_space', () {
      var ref = StorageFileRef(
        'bucket.appspot.com',
        'test/with space/file.jpg',
      );
      expect(ref.bucket, 'bucket.appspot.com');
      expect(ref.path, 'test/with space/file.jpg');
      expect(
        ref.toString(),
        'gs://bucket.appspot.com/test/with%20space/file.jpg',
      );

      ref = StorageFileRef.fromLink(ref.toLink());
      expect(ref.bucket, 'bucket.appspot.com');
      expect(ref.path, 'test/with space/file.jpg');

      var uri = Uri.parse(
        'gs://test.appspot.com',
      ).replace(path: 'test/with space/file.jpg');
      ref = StorageFileRef.fromLink(uri);
      expect(ref.bucket, 'test.appspot.com');
      expect(ref.path, 'test/with space/file.jpg');
      expect(ref.toString(), uri.toString());
    });
    test('special characters round trip', () {
      for (var path in [
        'a#1.png',
        'dir/what?.txt',
        '100%.txt',
        'p%20q.txt',
        '%41/b.txt',
        'é/ü.txt',
        'a+b&c=d.txt',
      ]) {
        var ref = StorageFileRef('bucket.appspot.com', path);
        var back = StorageFileRef.fromLink(ref.toLink());
        expect(back.bucket, 'bucket.appspot.com', reason: path);
        expect(back.path, path, reason: path);
        // The string form too
        back = StorageFileRef.fromLink(Uri.parse(ref.toString()));
        expect(back.path, path, reason: path);
      }
      expect(StorageFileRef('b', 'a#1.png').toString(), 'gs://b/a%231.png');
    });
  });
}
