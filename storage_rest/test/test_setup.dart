import 'dart:async';

import 'package:tekartik_firebase_rest/src/test/test_setup.dart';
import 'package:tekartik_firebase_rest/src/test/test_setup.dart' as firebase;

export 'package:tekartik_firebase_rest/src/test/test_setup.dart' hide setup;

const _firebaseStorageScopes = [
  'https://www.googleapis.com/auth/devstorage.read_only',
  firebaseGoogleApisUserEmailScope,
];

Future<Context> setup() async {
  return await firebase.setup(scopes: _firebaseStorageScopes);
}
