import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage/storage.dart';

import 'storage_sim_server_service.dart';

class StorageSimPlugin implements FirebaseSimPlugin {
  final storageSimServerService = StorageSimServerService();
  final StorageService storageService;

  StorageSimPlugin({required this.storageService}) {
    storageSimServerService.storageSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => storageSimServerService;
}
