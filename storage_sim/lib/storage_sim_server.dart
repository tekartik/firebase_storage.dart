/// Server side of the storage sim: register
/// `StorageSimPlugin(storageService: <a local storage service>)` in
/// `firebaseSimServe(..., plugins: [...])` (Dart VM only).
library;

export 'src/storage_sim_plugin.dart' show StorageSimPlugin;
