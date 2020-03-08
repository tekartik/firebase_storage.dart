@TestOn('browser')
library tekartik_firebase_storage_browser.storage_browser_test;

import 'package:tekartik_firebase_browser/firebase_browser.dart';
import 'package:tekartik_firebase_storage_browser/storage_browser.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

void main() async {
  var options = await setup();
  if (options == null) {
    test('no setup', () {});
    return;
  }
  var firebase = firebaseBrowser;

  group('browser', () {
    run(firebase: firebase, storageService: storageService, options: options);
  });
}
