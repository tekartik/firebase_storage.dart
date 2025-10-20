// ignore_for_file: avoid_print

import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim_server.dart';

import 'example_io_client.dart';

Future<void> main(List<String> args) async {
  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: urlKvPort,
    plugins: [StorageSimPlugin(storageService: storageServiceMemory)],
  );
  print('url ${firebaseSimServer.url}');
}
