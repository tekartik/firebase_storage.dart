
import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:test/test.dart';

void run({@required Firebase firebase,
  @required StorageServiceProvider provider,
  AppOptions options}) {
  App app = firebase.initializeApp();

  tearDownAll(() {
    return app.delete();
  });

  runApp(app, service: provider.storageService(firebase));
}

String defaultBucketName = "tekartik-free-dev.appspot.com";
runApp(App app, {@required StorageService service}) {
  var storage = service.storage(app);
  group('storage', () {
    test('storage', () {
      expect(storage, isNotNull);
    });

    group('bucket', () {
      test('default_bucket', () {
        var bucket = storage.bucket();
        expect(bucket, isNotNull);
        //expect(bucket.name, isNotNull);
      });

      test('bucket', () {
        var bucket = storage.bucket("test");
        expect(bucket, isNotNull);
        expect(bucket.name, "test");
      });
    });

    group('file', () {
      var bucket = storage.bucket(defaultBucketName);
      test('exists', () async {
        var file = bucket.file("dummy-file-that-should-not-exists");
        expect(await file.exists(), isFalse);
      });

      test('save_download_delete', () async {
        var file = bucket.file("file.txt");
        await file.save("simple content");
        expect(await file.exists(), isTrue);
        expect(String.fromCharCodes(await file.download()), "simple content");
        await file.delete();
      });
    });
  });
}
