import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_storage/utils/link.dart';

void main() {
  group('link', () {
    test('link', () {
      var uri = Uri.parse('gs://test.appspot.com/test/sub.jpg');
      var ref = StorageFileRef.fromLink(uri);
      expect(ref.bucket, 'test.appspot.com');
      expect(ref.path, 'test/sub.jpg');
      expect(ref.toString(), uri.toString());
    });
  });
}
