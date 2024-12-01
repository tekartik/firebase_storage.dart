import 'package:tekartik_firebase_browser/firebase_browser.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('compile on io', () {
    try {
      // ignore: deprecated_member_use
      firebaseBrowser;
    } catch (e) {
      // print(e);
    }
  });
}
