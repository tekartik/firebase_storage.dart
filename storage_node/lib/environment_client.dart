import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:tekartik_common_utils/env_utils.dart';

var _env = platform.environment;
StorageOption _tsStorageOptionsFromEnv;

/// Storage option
class StorageOption {
  final String storageBucket;

  StorageOption({this.storageBucket});
}

StorageOption getStorageOptionsFromEnv(Map<String, String> env) {
  var storageBucket = env['storageBucket'];

  return StorageOption(
    storageBucket: storageBucket,
  );
}

/// Get storage option from env on node, dummy on io
StorageOption get storageOptionsFromEnv => _tsStorageOptionsFromEnv ??= () {
      if (isRunningAsJavascript) {
        return getStorageOptionsFromEnv(_env);
      } else {
        // io sim
        return StorageOption(storageBucket: 'local');
      }
    }();
