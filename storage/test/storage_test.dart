library tekartik_firebase_storage.storage__test;

import 'package:tekartik_firebase_storage/storage.dart';
import 'package:test/test.dart';

class StorageMock with StorageMixin {}

class BucketMock with BucketMixin {}

class FileMock with FileMixin {}

void main() {
  group('storage', () {
    test('api', () {
      // Exported
      expect(Storage, isNotNull);
      expect(File, isNotNull);
      expect(Bucket, isNotNull);
      expect(StorageService, isNotNull);
    });
  });
}
