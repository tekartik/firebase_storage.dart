import 'package:meta/meta.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:test/test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:path/path.dart';

/// Storage option
class TestStorageOptions {
  final String bucket;
  final String rootPath;

  TestStorageOptions({this.bucket, this.rootPath});

  @override
  String toString() => {'bucket': bucket, 'rootPath': rootPath}.toString();
}

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

void runApp(App app,
    {@required StorageService storageService,
    TestStorageOptions storageOptions}) {
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
      print('#: ${app.options.storageBucket?.runtimeType}');
      print(app.options.storageBucket == null);
      var bucket = app.options.storageBucket == null ? null : storage.bucket();
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
    },
        skip: app.options.storageBucket == null
            ? 'No storage bucket define in FIREBASE_CONFIG'
            : false);

    group('test bucket', () {
      var bucket = storageOptions?.bucket == null
          ? null
          : storage.bucket(storageOptions.bucket);
      var rootPath = storageOptions?.rootPath;
      String getFullPath(String path) {
        if (rootPath == null) {
          return path;
        } else {
          return url.join(rootPath, path);
        }
      }

      test('exists', () async {
        var file = bucket.file('dummy-file-that-should-not-exists');
        expect(await file.exists(), isFalse);
      });

      test('save_file', () async {
        var file = bucket.file(getFullPath('simple_file.txt'));
        try {
          await file.delete();
        } catch (_) {}
        var content =
            'simple content: ${DateTime.now().toUtc().toIso8601String()}';
        await file.save(content);
        expect(await file.exists(), isTrue);
        expect(String.fromCharCodes(await file.download()), content);
      });
    },
        skip: storageOptions?.bucket == null
            ? 'No firebaseStorageTestBucket defined'
            : false);
  });
}
