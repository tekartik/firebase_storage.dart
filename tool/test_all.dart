//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

/*
Future testStorage() async {
  var dir = 'storage';
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}
*/
Future testStorageFs() async {
  var dir = 'storage_fs';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testStorageBrowser() async {
  var dir = 'storage_browser';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['chrome']))..workingDirectory = dir);
}

Future testStorageSimBrowser() async {
  // var dir = 'storage_sim_browser';
}

Future testStorageNode() async {
  var dir = 'storage_node';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future testStorageFlutter() async {
  // var dir = 'storage_flutter';
}

Future testStorageTest() async {
  // var dir = 'storage_test';
}

Future main() async {
  Future.wait([
    testStorageBrowser(),
    testStorageFs(),
    // testStorageNode(),

    //await testStorageNode();

    //await testStorageFlutter();
    testStorageTest()
  ]);
}
