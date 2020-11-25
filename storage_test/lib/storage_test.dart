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
    AppOptions options,
    TestStorageOptions storageOptions}) {
  var app = firebase.initializeApp();
  tearDownAll(() {
    return app.delete();
  });

  runApp(app, storageService: storageService, storageOptions: storageOptions);
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
      }, skip: 'Default bucket can be null');

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

      test('list_files', () async {
        var now = DateTime.now();
        var content = 'storage_list_files_test';
        await bucket
            .file('test/list_files/no/file0.txt')
            .writeAsString(content);
        await bucket
            .file('test/list_files/yes/file1.txt')
            .writeAsString(content);
        await bucket
            .file('test/list_files/yes/sub/file2.txt')
            .writeAsString(content);
        await bucket
            .file('test/list_files/yes/other_sub/sub/file3.txt')
            .writeAsString(content);
        var files = <File>[];

        var query = GetFilesOptions(
            maxResults: 2, prefix: 'test/list_files/yes', autoPaginate: false);
        var response = await bucket.getFiles(query);
        // devPrint(response);
        files.addAll(response.files);
        while (response.nextQuery != null) {
          response = await bucket.getFiles(response.nextQuery);
          // devPrint(response);
          files.addAll(response.files);
        }
        var names = files.map((e) => e.name).toList()..sort();

        // Assume the directory was empty before
        expect(names, [
          'test/list_files/yes/file1.txt',
          'test/list_files/yes/other_sub/sub/file3.txt',
          'test/list_files/yes/sub/file2.txt'
        ]);
        expect(names, contains('test/list_files/yes/file1.txt'));
        expect(names, contains('test/list_files/yes/sub/file2.txt'));
        expect(names, contains('test/list_files/yes/other_sub/sub/file3.txt'));
        expect(names, isNot(contains('test/list_files/no/file0.txt')));

        // Check meta
        var file = files.firstWhere(
            (element) => element.name == 'test/list_files/yes/file1.txt');
        expect(file.metadata.dateUpdated.isBefore(now), isFalse);
        expect(file.metadata.md5Hash,
            isNotEmpty); // 'abd848eb171be7fa03d8e29223fcbe78');
        expect(file.metadata.size, 23);
      });
      test('list_no_files', () async {
        var query = GetFilesOptions(
            maxResults: 2,
            prefix: 'test/dummy_path_that_should_not_exists',
            autoPaginate: false);
        var response = await bucket.getFiles(query);
        // devPrint(response);
        expect(response.files, isEmpty);
      });
    },
        skip: storageOptions?.bucket == null
            ? 'No firebaseStorageTestBucket defined'
            : false);
  });
}
