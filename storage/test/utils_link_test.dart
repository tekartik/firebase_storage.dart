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
  });
}
