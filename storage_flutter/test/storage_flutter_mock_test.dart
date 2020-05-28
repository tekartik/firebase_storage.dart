library tekartik_firebase_storage_flutter.test.storage_flutter_mock_test;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_storage_flutter/src/storage_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    test('ref', () {
      var storage = StorageFlutter(FirebaseStorage.instance);
      var bucket = storage.bucket('test');
      expect(bucket.name, 'test');
    });
  });
}
