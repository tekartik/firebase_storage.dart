library;

import 'package:tekartik_common_utils/common_utils_import.dart';

// ignore: unused_import
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

var _bucketName = 'my_sim_bucket';
Future main() async {
  //debugFirebaseSimServer = devTrue;
  //debugFirebaseSimClient = devTrue;
  // debugSimServerMessage = true;

  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var app = firebase.initializeApp();

  /// Need to create the bucket.
  await storageServiceSim
      .storage(app)
      .bucket(_bucketName)
      .create(); // Create default bucket

  // ignore: dead_code, curly_braces_in_flow_control_structures
  runStorageAppTests(
    app,
    storageService: storageServiceSim,
    storageOptions: TestStorageOptions(bucket: _bucketName),
  );

  test('projectId', () {
    expect(app.options.projectId, 'sim');
  });

  test('service and storage singletons', () {
    expect(identical(storageServiceSim, storageServiceSim), isTrue);
    expect(storageServiceSim.storage(app), storageServiceSim.storage(app));
  });

  test('file bucket and metadata', () async {
    var bucket = storageServiceSim.storage(app).bucket(_bucketName);
    var file = bucket.file('test/sim_file_bucket.txt');
    // Only a listed file has metadata.
    expect(file.metadata, isNull);
    expect(file.bucket.name, _bucketName);
    await file.writeAsString('sim');
    var listed = (await bucket.getFiles(
      GetFilesOptions(prefix: 'test/sim_file_bucket'),
    )).files.single;
    expect(listed.bucket.name, _bucketName);
    expect(listed.metadata!.size, 3);
    await file.delete();
  });

  tearDownAll(() async {
    await close(testContext);
  });
}
