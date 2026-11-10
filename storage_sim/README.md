# tekartik_firebase_storage_sim

A Firebase `Storage` whose files live in another process: a firebase sim
server (`tekartik_firebase_sim`) hosts a local storage (usually
`tekartik_firebase_storage_fs`, in memory or on disk) and clients (Dart VM,
browser, Flutter) reach its buckets and files over a web socket. Handy to
give a browser or several processes one local bucket during development and
tests.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_storage_sim:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage_sim
  tekartik_firebase_sim:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_sim
  # The server side hosts a local storage on a local firebase.
  tekartik_firebase_storage_fs:
    git:
      url: https://github.com/tekartik/firebase_storage.dart
      path: storage_fs
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  # The in memory transport of the example below.
  tekartik_web_socket:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket
```

Server and client in one program, over the in memory transport:

```dart
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim.dart';
import 'package:tekartik_firebase_storage_sim/storage_sim_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';

Future<void> main() async {
  // Server: an in memory storage published over the sim protocol.
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelFactoryMemory.server,
    plugins: [StorageSimPlugin(storageService: newStorageServiceMemory())],
  );

  // Client.
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelFactoryMemory.client,
    uri: simServer.uri,
  );
  var app = firebase.initializeApp() as FirebaseAppSim;
  var bucket = storageServiceSim.storage(app).bucket('my_bucket');
  await bucket.create();

  var file = bucket.file('notes/hello.txt');
  await file.writeAsString('hello sim');
  print(await file.readAsString());
  var files = (await bucket.getFiles()).files;
  print(files.map((file) => '${file.name} ${file.metadata?.size}').toList());

  // delete() leaves the connection of the app open: close it.
  var simClient = await app.simClient;
  await app.delete();
  await simClient.close();
  await simServer.close();
}
```

In real use the server runs in a Dart VM process
(`webSocketChannelServerFactoryIo` of `tekartik_web_socket_io`,
`port: firebaseSimDefaultPort`) and the clients connect with
`getFirebaseSim(uri: getFirebaseSimLocalhostUri())`.

## Platforms

| Side | Library | Runs on |
|---|---|---|
| client | `storage_sim.dart` (`storageServiceSim`) | Dart VM, web, Flutter |
| server | `storage_sim_server.dart` (`StorageSimPlugin`) | Dart VM only |

## What to know

* `storage_sim.dart` only exports `storageServiceSim`: import
  `package:tekartik_firebase_storage/storage.dart` for `Bucket`, `File`,
  `GetFilesOptions`...
* Create a bucket (`bucket.create()`) before writing to it.
  `storage.bucket()` without name is `app.options.storageBucket`, else
  `'sim.bucket'`.
* Supported: bucket `create`, `exists`, `getFiles` (prefix, page size, page
  token); file `exists`, `upload` (content type, cache control), `download`,
  `getMetadata`, `delete`. `storage.ref()` (download urls) is not.
* `file.metadata` is only set on the files listed by `getFiles`.
* Bytes travel as JSON lists of numbers: keep the files small.
* `app.delete()` leaves the connection open: close `await app.simClient`, as
  above, or a program does not exit.
* A development tool: the transport is not authenticated and there are no
  security rules.

The [tekartik-firebase-storage-sim-setup skill](skills/tekartik-firebase-storage-sim-setup/SKILL.md)
has more examples (io server and client, listing pages, shared test suite).
