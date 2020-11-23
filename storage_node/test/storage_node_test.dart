@TestOn('node')
library tekartik_firebase_storage_node.storage_node_test;

import 'package:node_interop/node_interop.dart' as interop;
import 'package:node_interop/util.dart' as interop;
import 'package:tekartik_firebase_node/firebase_node.dart' show firebaseNode;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_storage_node/storage_node.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_environment_client.dart';

Map errorToMap(e) {
  var map = <String, dynamic>{};
  for (var key in interop.objectKeys(e)) {
    //print('$key ${e[key]}');
    print(key);
    print(interop.getProperty(e, key));
    //map[key] = e[key];
  }
  return map;
}

Future<void> main() async {
  var options = storageOptionsFromEnv;
  var app = await firebaseNode.initializeAppAsync(
      //options: AppOptions(storageBucket: options.storageBucket)
      );
  test('node_env', () async {
    print(options);
  });
  group('node', () {
    setUpAll(() async {});
    runApp(app,
        storageService: storageServiceNode,
        storageOptions: storageOptionsFromEnv);
    tearDownAll(() {
      return app.delete();
    });

    /*
    test('save', () async {
      var bucket = app.storage().bucket('test');
      print('exists ${await bucket.exists()}');
      if (!await bucket.exists()) {
        await bucket.create();
      }
      var file = bucket.file('file');
      try {
        await file.save('content');
      } catch (e) {
        print(objectKeys(e));
        print(e);
        print(errorToMap(e));
      }
    }, skip: true);
    */

    test('app', () {
      print(app.options.apiKey);
      print(app.options.storageBucket);
      print(app.options.projectId);
    });

    test('custom', () async {
      var storageNode = storageServiceNode.storage(app) as StorageNode;
      var bucketNode =
          storageNode.bucket(storageOptionsFromEnv.bucket) as BucketNode;
      var query =
          GetFilesOptions(maxResults: 10, prefix: 'tests', autoPaginate: false);
      while (true) {
        var response = await bucketNode.getFiles(query);
        response = await bucketNode.getFiles(response.nextQuery);
        query = response.nextQuery;
        if (query == null) {
          break;
        }
      }
    });
    // runApp(app, storageService: storageService);
  }, skip: options == null);
}
