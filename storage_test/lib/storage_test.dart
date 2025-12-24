import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_test/src/import.dart';

export 'package:tekartik_firebase_storage/storage.dart';

/// Storage option
class TestStorageOptions {
  final String? bucket;
  final String? rootPath;

  TestStorageOptions({this.bucket, this.rootPath});

  @override
  String toString() => {'bucket': bucket, 'rootPath': rootPath}.toString();
}

@Deprecated('Use runStorageTests')
void run({
  required Firebase firebase,
  required StorageService storageService,
  AppOptions? options,
  required TestStorageOptions storageOptions,
}) => runStorageTests(
  firebase: firebase,
  storageService: storageService,
  options: options,
  storageOptions: storageOptions,
);

void runStorageTests({
  required Firebase firebase,
  required StorageService storageService,
  AppOptions? options,
  required TestStorageOptions storageOptions,
}) {
  var app = firebase.initializeApp(options: options);

  tearDownAll(() {
    return app.delete();
  });

  runStorageAppTests(
    app,
    storageService: storageService,
    storageOptions: storageOptions,
  );
}

@Deprecated('Use runStorageAppTests')
void runApp(
  App app, {
  required StorageService storageService,
  required TestStorageOptions storageOptions,
}) => runStorageAppTests(
  app,
  storageService: storageService,
  storageOptions: storageOptions,
);

void runStorageAppTests(
  App app, {
  required StorageService storageService,
  required TestStorageOptions storageOptions,
}) {
  String filePath(String path) {
    if (storageOptions.rootPath != null) {
      return url.join(storageOptions.rootPath!, path);
    }
    return path;
  }

  var storageBucket =
      storageOptions.bucket ?? appOptionsGetStorageBucket(app.options);
  var storage = storageService.storage(app);
  test('app', () {
    expect(storage.app, app);
    expect(storage.service, storageService);
    expect(storageService.storage(app), storage);
    expect(app.getProduct<FirebaseStorage>(), storage);
  });
  group('storage', () {
    var bucket = storage.bucket(storageBucket);
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
      test('exists', () async {
        expect(await bucket.exists(), isTrue);
        expect(
          await storage.bucket('dummy-azeiourieozuoe-dev.appspot.com').exists(),
          isFalse,
        );
      });
    });

    group('file', () {
      // print('#: ${storageBucket.runtimeType}');
      var bucket = storage.bucket(storageBucket);

      test('exists', () async {
        var file = bucket.file(filePath('dummy-file-that-should-not-exists'));

        expect(await file.exists(), isFalse);
      });
      test('save_download_delete', () async {
        var file = bucket.file(filePath('file.to_delete.txt'));
        await file.exists();
        await file.writeAsString('simple content');
        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), 'simple content');
        await file.delete();
        expect(await file.exists(), isFalse);
      });
    });

    group('test bucket', () {
      String getFullPath(String path) => filePath(path);

      test('write_read_file', () async {
        var file = bucket.file(getFullPath('simple_file.txt'));
        try {
          await file.delete();
        } catch (_) {}

        final now = DateTime.now().toUtc();
        var content = now.toIso8601String();
        await file.writeAsString(content);
        expect(await file.exists(), isTrue);
        // Last text
        var readContent = await file.readAsString();
        var readDateTime = DateTime.tryParse(readContent)!;
        // expect(String.fromCharCodes(await file.download()), content);
        // There is a one hour cache
        expect(now.difference(readDateTime), lessThan(Duration(minutes: 65)));

        readContent = utf8.decode(await file.readAsBytes());
        readDateTime = DateTime.tryParse(readContent)!;
        // expect(String.fromCharCodes(await file.download()), content);
        // There is a one hour cache
        expect(now.difference(readDateTime), lessThan(Duration(minutes: 65)));
      });

      test('list_files', () async {
        var now = DateTime.now();
        var content = 'storage_list_files_test';
        await bucket
            .file(filePath('test/list_files/no/file0.txt'))
            .writeAsString(content);
        await bucket
            .file(filePath('test/list_files/yes/file1.txt'))
            .writeAsString(content);
        await bucket
            .file(filePath('test/list_files/yes/sub/file2.txt'))
            .writeAsString(content);
        await bucket
            .file(filePath('test/list_files/yes/other_sub/sub/file3.txt'))
            .writeAsString(content);

        var files = <File>[];
        var listFilePath = filePath('test/list_files/yes');

        var query = GetFilesOptions(
          maxResults: 2,
          prefix: listFilePath,
          autoPaginate: false,
        );
        var response = await bucket.getFiles(query);
        files.addAll(response.files);

        String? lastFirstPath;
        while (response.nextQuery != null) {
          response = await bucket.getFiles(response.nextQuery);
          var firstPath = response.files.firstOrNull?.name;
          if (firstPath != null) {
            expect(firstPath, isNot(lastFirstPath));
          }
          lastFirstPath = firstPath;
          files.addAll(response.files);
        }
        var names = files.map((e) => e.name).toList()..sort();
        // Assume the directory was empty before
        expect(names, [
          filePath('test/list_files/yes/file1.txt'),
          filePath('test/list_files/yes/other_sub/sub/file3.txt'),
          filePath('test/list_files/yes/sub/file2.txt'),
        ]);
        expect(names, contains(filePath('test/list_files/yes/file1.txt')));
        expect(names, contains(filePath('test/list_files/yes/sub/file2.txt')));
        expect(
          names,
          contains(filePath('test/list_files/yes/other_sub/sub/file3.txt')),
        );
        expect(
          names,
          isNot(contains(filePath('test/list_files/no/file0.txt'))),
        );
        // Check meta
        var file = files.firstWhere(
          (element) =>
              element.name == filePath('test/list_files/yes/file1.txt'),
        );
        // This happens on flutter.
        if (file.metadata != null) {
          expect(file.metadata!.dateUpdated.isBefore(now), isFalse);
          expect(
            file.metadata!.md5Hash,
            isNotEmpty,
          ); // 'abd848eb171be7fa03d8e29223fcbe78');
          expect(file.metadata!.size, 23);
        }
      });

      test('list_files_meta', () async {
        var content = 'storage_list_files_test';
        await bucket
            .file(filePath('test/meta/file0.txt'))
            .writeAsString(content);

        var query = GetFilesOptions(
          maxResults: 2,
          prefix: filePath('test/meta/'),
          autoPaginate: false,
        );
        var response = await bucket.getFiles(query);
        var file1 = response.files.first;

        response = await bucket.getFiles(query);
        var file2 = response.files.first;
        // This happens on flutter.
        if (file1.metadata != null) {
          expect(file1.metadata!.size, file2.metadata!.size);
          expect(file1.metadata!.dateUpdated, file2.metadata!.dateUpdated);
          expect(file1.metadata!.md5Hash, file2.metadata!.md5Hash);
        }
      });

      test('file_get_meta', () async {
        var content = 'storage_get_meta_test';
        var file = bucket.file(filePath('test/get_meta/file0.txt'));
        if (await file.exists()) {
          await file.delete();
        }
        expect(await file.exists(), isFalse);

        try {
          await file.getMetadata();
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        await file.writeAsString(content);

        var metadata = await file.getMetadata();
        expect(metadata.size, greaterThanOrEqualTo(content.length));
        expect(metadata.dateUpdated, isNotNull);
        expect(metadata.md5Hash, isNotNull);
      });

      test('file_with_meta', () async {
        var content = 'storage_with_meta_test';
        var file = bucket.file(filePath('test/with_meta/file0.txt'));
        if (await file.exists()) {
          await file.delete();
        }
        expect(await file.exists(), isFalse);

        try {
          await file.getMetadata();
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        await file.upload(
          utf8.encode(content),
          options: StorageUploadFileOptions(contentType: 'text/plain'),
        );

        var metadata = await file.getMetadata();
        expect(metadata.size, greaterThanOrEqualTo(content.length));
        expect(metadata.dateUpdated, isNotNull);
        expect(metadata.md5Hash, isNotNull);
        expect(metadata.contentType, 'text/plain');
      });
      test('file_with_detected_meta', () async {
        var content = 'storage_with_meta_detected_test';
        var file = bucket.file(filePath('test/with_detected_meta/file0.txt'));
        if (await file.exists()) {
          await file.delete();
        }
        expect(await file.exists(), isFalse);

        try {
          await file.getMetadata();
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        await file.upload(utf8.encode(content));

        var metadata = await file.getMetadata();
        expect(metadata.size, greaterThanOrEqualTo(content.length));
        expect(metadata.dateUpdated, isNotNull);
        expect(metadata.md5Hash, isNotNull);
        expect(metadata.contentType, 'text/plain');
      });

      test('file_no_type', () async {
        var content = 'storage_no_meta_detected_test';
        var file = bucket.file(filePath('test/no_detected_meta/file0.bin'));
        if (await file.exists()) {
          await file.delete();
        }
        expect(await file.exists(), isFalse);

        try {
          await file.getMetadata();
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }

        await file.upload(utf8.encode(content));

        var metadata = await file.getMetadata();
        expect(metadata.size, greaterThanOrEqualTo(content.length));
        expect(metadata.dateUpdated, isNotNull);
        expect(metadata.md5Hash, isNotNull);
        expect(metadata.contentType, 'application/octet-stream');
      });
      test('list_no_files', () async {
        var query = GetFilesOptions(
          maxResults: 2,
          prefix: filePath('test/dummy_path_that_should_not_exists'),
          autoPaginate: false,
        );
        var response = await bucket.getFiles(query);
        // devPrint(response);
        expect(response.files, isEmpty);
      });
    });
  });
}
