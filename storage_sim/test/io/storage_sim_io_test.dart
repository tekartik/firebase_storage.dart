@TestOn('vm')
library;

import 'dart:async';

import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

var _bucketName = 'my_sim_io_bucket';
Future main() async {
  // debugSimServerMessage = true;

  var testContext = await initTestContextSimIo();
  var firebase = testContext.firebase;
  var app = firebase.initializeApp();

  /// Need to create the bucket.
  await storageServiceSim.storage(app).bucket(_bucketName).create(); // Cre
  runStorageAppTests(
    app,

    storageService: storageServiceSim,
    storageOptions: TestStorageOptions(bucket: _bucketName),
  );

  tearDownAll(() async {
    await close(testContext);
  });
}
