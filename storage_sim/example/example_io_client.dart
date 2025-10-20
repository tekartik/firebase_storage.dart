import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_client.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_test/menu/storage_client_menu.dart';

var urlKv = 'storage_sim_example.url'.kvFromVar(
  defaultValue: 'ws://localhost:${firebaseSimDefaultPort.toString()}',
);

int? get urlKvPort => int.tryParse((urlKv.value ?? '').split(':').last);
Future<void> main(List<String> args) async {
  var firebase = getFirebaseSim(uri: Uri.parse(urlKv.value!));
  var app = firebase.initializeApp();
  debugFirebaseSimClient = true;
  var storage = storageServiceSim.storage(app); // .debugQuickLoggerWrapper();
  await mainMenu(args, () {
    firebaseStorageMainMenu(
      context: StorageMainMenuContext(
        bucket: 'test_bucket',
        rootPath: 'tests/sim',
        storage: storage,
      ),
    );
    keyValuesMenu('kv', [urlKv]);
  });
}
