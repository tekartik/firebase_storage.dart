import 'package:tekartik_app_node_utils/node_utils.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';

var _env = platform.environment;
TestStorageOptions _storageOptionsFromEnv;

TestStorageOptions getStorageOptionsFromEnv(Map<String, String> env) {
  var storageBucket = env['firebaseStorageTestBucket'];
  var rootPath = env['firebaseStorageTestRootPath'];
  return TestStorageOptions(bucket: storageBucket, rootPath: rootPath);
}

/// Get storage option from env on node, dummy on io
TestStorageOptions get storageOptionsFromEnv => _storageOptionsFromEnv ??= () {
      if (isRunningAsJavascript) {
        return getStorageOptionsFromEnv(_env);
      } else {
        // io sim
        return TestStorageOptions(bucket: 'local');
      }
    }();
