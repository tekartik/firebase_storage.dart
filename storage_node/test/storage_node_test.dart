@TestOn('node')
library tekartik_firebase_storage_node.storage_node_test;

import 'package:node_interop/node_interop.dart' as interop;
import 'package:node_interop/util.dart' as interop;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_node/firebase_node.dart' show firebaseNode;
import 'package:tekartik_firebase_storage_node/environment_client.dart';
import 'package:test/test.dart';

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

void main() {
  var options = storageOptionsFromEnv;
  test('node_env', () async {
    print(options);
  });
  group('node', () {
    App app;

    setUpAll(() async {
      app = await firebaseNode.initializeAppAsync(
          options: AppOptions(storageBucket: options.storageBucket));
    });
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
      print(app.options.projectId);
    });
    // runApp(app, storageService: storageService);
  }, skip: options == null);
}
