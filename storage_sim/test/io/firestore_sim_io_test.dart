@TestOn('vm')
library;

import 'dart:async';

import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugSimServerMessage = true;

  var testContext = await initTestContextSimIo();
  var firebase = testContext.firebase;
  runStorageTests(
    firebase: firebase,
    storageService: storageServiceSim,
    storageOptions: TestStorageOptions(),
  );

  tearDownAll(() async {
    await close(testContext);
  });
}
