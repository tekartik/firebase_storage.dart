@TestOn('browser')
library tekartik_firebase_storage_browser.storage_browser_test;

import 'package:tekartik_firebase_storage_browser/storage_browser.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

void main() async {
  var options = await setup();
  // var firebase = firebaseBrowser;
  group('browser', () {
    test('api', () {
      storageServiceBrowser;
    });
    // run(firebase: firebase, storageService: storageService, options: options);
  }, skip: options == null);
}
