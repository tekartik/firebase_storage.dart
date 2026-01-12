import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';
import 'package:tekartik_firebase_storage/storage.dart';

import 'storage_sim_server_service.dart';

/// Storage simulation plugin.
class StorageSimPlugin
    with FirebaseSimPluginDefaultMixin
    implements FirebaseSimPlugin {
  /// Storage simulation server service.
  final storageSimServerService = StorageSimServerService();

  /// Storage service.
  final StorageService storageService;

  /// Create storage simulation plugin.
  StorageSimPlugin({required this.storageService}) {
    storageSimServerService.storageSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => storageSimServerService;
}
