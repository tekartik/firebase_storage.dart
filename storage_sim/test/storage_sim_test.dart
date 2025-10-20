library;

import 'package:tekartik_common_utils/common_utils_import.dart';
// ignore: unused_import
import 'package:tekartik_firebase_sim/firebase_sim_client.dart';
// ignore: unused_import
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

var _bucketName = 'my_sim_bucket';
Future main() async {
  // debugFirebaseSimServer = devWarning(true);
  // debugFirebaseSimClient = devWarning(true);
  // debugSimServerMessage = true;

  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var app = firebase.initializeApp();

  /// Need to create the bucket.
  await storageServiceSim
      .storage(app)
      .bucket(_bucketName)
      .create(); // Create default bucket

  if (false) // Temp
    // ignore: dead_code, curly_braces_in_flow_control_structures
    runStorageAppTests(
      app,
      storageService: storageServiceSim,
      storageOptions: TestStorageOptions(bucket: _bucketName),
    );

  test('projectId', () {
    expect(app.options.projectId, 'sim');
  });

  tearDownAll(() async {
    await close(testContext);
  });
}
