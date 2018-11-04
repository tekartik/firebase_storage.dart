# firebase_storage.dart

Firestore storage dart common interface and implementation for Browser, VM, node and flutter


## Firebase Initialization


### Usage on node

```dart
import 'package:tekartik_firebase_node/firebase_node.dart';
import 'package:tekartik_firebase_storage_node/storage_node.dart';

void main() {
  var storage = storageService(firebase);
  // ...
}
```  

### Usage on flutter

```dart
import 'package:tekartik_firebase_flutter/firebase_flutter.dart';

void main() {
  var firebase = firebaseFlutter;
  // ...
}
```  

### Usage on fs_shim (io simulation)

```dart
import 'package:tekartik_firebase_sembast/firebase_sembast_io.dart';

void main() {
  var firebase = firebaseSembastIo;
  // ...
}
```  


## Storage access

Experimental, not fully implemented yet
```dart
var storage = storageService(firebase);
// ...

```  

