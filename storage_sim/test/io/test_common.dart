import 'dart:async';

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_plugin.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

class TestContext {
  late FirebaseSimServer simServer;
  late Firebase firebase;
}

// using real websocker
Future<TestContext> initTestContextSimIo() async {
  var testContext = TestContext();
  testContext.simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())],
  );
  testContext.firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryIo,
    uri: testContext.simServer.uri,
  );

  return testContext;
}

Future close(TestContext testContext) async {
  await testContext.simServer.close();
}
