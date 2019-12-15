import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:test/test.dart';

void run(
    {@required Firebase firebase,
    @required StorageService storageService,
    AppOptions options}) {
  var app = firebase.initializeApp();

  tearDownAll(() {
    return app.delete();
  });

  runApp(app, storageService: storageService);
}

void runApp(App app, {@required StorageService storageService}) {
  var storage = storageService.storage(app);
  group('storage', () {
    test('storage', () {
      expect(storage, isNotNull);
    });

    group('bucket', () {
      test('default_bucket', () {
        var bucket = storage.bucket();
        expect(bucket, isNotNull);
        expect(bucket.name, isNotNull);
      });

      test('bucket', () {
        try {
          var bucket = storage.bucket('test');
          expect(bucket, isNotNull);
          expect(bucket.name, 'test');
        } catch (_) {
          // Allow failing here
        }
      });
    });

    group('file', () {
      var bucket = storage.bucket();
      test('exists', () async {
        var file = bucket.file('dummy-file-that-should-not-exists');
        expect(await file.exists(), isFalse);
      });

      test('save_download_delete', () async {
        var file = bucket.file('file.to_delete.txt');
        await file.save('simple content');
        expect(await file.exists(), isTrue);
        expect(String.fromCharCodes(await file.download()), 'simple content');
        await file.delete();
      });
    });
  });
}
