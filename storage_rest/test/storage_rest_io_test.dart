@TestOn('vm')
library tekartik_firebase_storage_rest.storage_rest_io_test;

import 'package:tekartik_firebase_storage_rest/storage_rest.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_environment_client.dart';
import 'test_setup.dart';

Future main() async {
  var context = await setup();
  group('rest_io', () {
    // Temp
    //context = null;
    if (context != null) {
      var firebase = firebaseRest;
      group('all', () {
        runStorageTests(
            firebase: firebase,
            storageService: storageServiceRest,
            options: context.options,
            storageOptions: storageOptionsFromEnv);
      });
    }
  }, skip: context == null);
}
