---
name: tekartik-firebase-storage-sim-setup
description: >-
  Use when serving or consuming Firebase Storage through the tekartik firebase
  simulator (websocket + JSON-RPC) with tekartik_firebase_storage_sim:
  storageServiceSim on the client, StorageSimPlugin(storageService:) plugged
  into firebaseSimServe on the server, getFirebaseSim / getFirebaseSimIo with
  webSocketChannelClientFactoryIo or webSocketChannelClientFactoryMemory,
  firebaseSimDefaultPort, the storage_sim.dart and storage_sim_server.dart
  imports, which Bucket/File operations the simulation supports, and running
  the tekartik_firebase_storage_test suite over the simulated link.
---

# tekartik_firebase_storage_sim: storage over the firebase simulator

`tekartik_firebase_storage_sim` exposes a `tekartik_firebase_storage`
implementation that forwards every call over a websocket JSON-RPC link
handled by `tekartik_firebase_sim`. The server side plugs a *real*
implementation (usually `tekartik_firebase_storage_fs` in memory or on disk)
behind a `StorageSimPlugin`; the client side only sees `Storage`, `Bucket` and
`File`. It is how browser or multi-process code reaches a local bucket.

## Guidelines

* Dependency (git, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_firebase_storage_sim:
      git:
        url: https://github.com/tekartik/firebase_storage.dart
        path: storage_sim
  ```
  It brings `tekartik_firebase_storage` and `tekartik_firebase_sim` only. The
  server also needs `tekartik_firebase_local` (the `Firebase` it serves),
  a backing implementation such as `tekartik_firebase_storage_fs`, and a
  websocket factory package (`tekartik_web_socket_io` on the VM): declare
  them yourself.
* Two public libraries, both tiny:
  - `package:tekartik_firebase_storage_sim/storage_sim.dart` exports exactly
    `storageServiceSim` (client side). It does **not** re-export the storage
    API, so import `package:tekartik_firebase_storage/storage.dart` as well
    for `Storage`, `Bucket`, `File`, `GetFilesOptions`...
  - `package:tekartik_firebase_storage_sim/storage_sim_server.dart` exports
    exactly `StorageSimPlugin` (server side).
  Never import `package:tekartik_firebase_storage_sim/src/...`.
* Server: `await firebaseSimServe(FirebaseLocal(),
  webSocketChannelServerFactory: webSocketChannelServerFactoryIo, port: ...,
  plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())])`
  (`firebaseSimServe` and `FirebaseSimServer` come from
  `package:tekartik_firebase_sim/firebase_sim_server.dart`). The returned
  server exposes `url` / `uri` (port `0` or a null `port` picks
  `firebaseSimDefaultPort`, 4996) and `close()`. The `storageService` you pass
  is the one that really stores the bytes; the plugin creates one product per
  client app, on the server's own local app.
* Client: `var firebase = getFirebaseSim(uri: Uri.parse('ws://localhost:4996'),
  clientFactory: webSocketChannelClientFactoryIo);` (or `getFirebaseSimIo` /
  `getFirebaseSimWeb`, which pick the factory for you), then
  `firebase.initializeApp()` and `storageServiceSim.storage(app)`. The app
  must come from a `FirebaseSim` (a plain `assert` fires otherwise). Its
  default `projectId` is `'sim'`.
* `storageServiceSim` is a getter that builds a new `StorageServiceSim` on
  every read: assign it once to a variable (or a final field) and reuse that
  instance, otherwise each access creates a separate product for the same app
  and `app.storage()` may not be the instance you hold.
* Buckets: `storage.bucket(name)`, or `storage.bucket()` which falls back to
  `app.options.storageBucket` and then to the literal `'sim.bucket'`. Create
  the bucket once (`await storage.bucket(name).create()`) before writing:
  the backing fs implementation reports `exists() == false` for an unknown
  bucket.
* Supported over the wire: `bucket.create()`, `bucket.exists()`,
  `bucket.getFiles()` (with `prefix`, `maxResults` and a real `pageToken` in
  `nextQuery`), `file.exists()`, `file.upload()` (with
  `StorageUploadFileOptions.contentType`), `file.readAsBytes()` /
  `readAsString()`, `file.delete()` and `file.getMetadata()`.
  `storage.ref(...)` is **not** implemented: it throws `UnimplementedError`,
  so there is no `getDownloadUrl()` in a simulation.
* `file.metadata` only holds the metadata cached by `bucket.getFiles()`;
  reading it on a `bucket.file(path)` reference throws. Use
  `await file.getMetadata()` there.
* Payloads are JSON arrays of byte values, so an upload or a download costs
  several times the file size in memory and message size on both ends: keep
  simulated objects small (fixtures, test assets), and do not benchmark
  throughput against it.
* Tests: build both ends in-process with the memory transport
  (`webSocketChannelServerFactoryMemory` /
  `webSocketChannelClientFactoryMemory` from `tekartik_web_socket`, also
  re-exported by `tekartik_web_socket_io`); nothing binds a real port. Always
  `await simServer.close()` in `tearDownAll`. The shared suite of
  `tekartik_firebase_storage_test` (`runStorageAppTests`) runs unchanged over
  the link.
* Keep the sim wiring at the edge of the program: shared code must depend on
  `Storage`/`Bucket`/`File` so the same code runs on the real backend.

## Examples

### Simulation server exposing an in-memory bucket

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main(List<String> args) async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: firebaseSimDefaultPort,
    plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())],
  );
  print('storage sim running on ${simServer.url}');
}
```

### Client talking to it

```dart
import 'dart:convert';

import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

var storageService = storageServiceSim; // Read the getter once.

Future<void> main() async {
  var firebase = getFirebaseSim(
    uri: getFirebaseSimLocalhostUri(),
    clientFactory: webSocketChannelClientFactoryIo,
  );
  var app = firebase.initializeApp();
  var storage = storageService.storage(app);

  var bucket = storage.bucket('test_bucket');
  await bucket.create();
  var file = bucket.file('tests/sim/hello.txt');
  await file.upload(
    utf8.encode('hello sim'),
    options: StorageUploadFileOptions(contentType: 'text/plain'),
  );
  print(await file.readAsString());
  print((await file.getMetadata()).size);
  await app.delete();
}
```

`file.writeAsString('hello sim')` is the shorter form when the content type
can be guessed from the extension.

### Both ends in one process, over the memory transport

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

/// Server and client in the same isolate, no port bound.
Future<(FirebaseSimServer, Storage)> newSimStorage(String bucketName) async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())],
  );
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );
  var storage = storageServiceSim.storage(firebase.initializeApp());
  await storage.bucket(bucketName).create();
  return (simServer, storage);
}
```

### Listing what the simulated bucket holds

```dart
import 'package:tekartik_firebase_storage/storage.dart';

Future<void> dumpBucket(Bucket bucket, String prefix) async {
  GetFilesOptions? query = GetFilesOptions(
    prefix: prefix,
    maxResults: 20,
    autoPaginate: false,
  );
  while (query != null) {
    var response = await bucket.getFiles(query);
    for (var file in response.files) {
      // metadata is filled by getFiles (only there).
      print('${file.name} ${file.metadata?.contentType}');
    }
    query = response.nextQuery;
  }
}
```

### Running the shared storage suite over the simulation

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim_server.dart';
import 'package:tekartik_firebase_storage_test/storage_test.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

var bucketName = 'my_sim_bucket';

Future<void> main() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())],
  );
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );
  var app = firebase.initializeApp();
  var storageService = storageServiceSim;
  await storageService.storage(app).bucket(bucketName).create();

  runStorageAppTests(
    app,
    storageService: storageService,
    storageOptions: TestStorageOptions(bucket: bucketName),
  );

  tearDownAll(() async {
    await simServer.close();
  });
}
```

## Common mistakes

* Reading `storageServiceSim` several times and comparing the resulting
  `Storage` instances (each read is a new service).
* Expecting `storage.ref(path)` / `getDownloadUrl()` to work: the simulation
  has no url scheme.
* Writing before `await bucket.create()`, or assuming
  `storage.bucket()` maps to `<projectId>.appspot.com` (it is
  `app.options.storageBucket` or `'sim.bucket'`).
* Reading `file.metadata` on a file that did not come from `getFiles()`.
* Forgetting `await simServer.close()`, which leaves the test isolate (or
  the port) hanging.
* Pushing large files through the link: bytes travel as JSON integer arrays.
* Passing a non-sim app (local, flutter, rest) to `storageServiceSim.storage`.
