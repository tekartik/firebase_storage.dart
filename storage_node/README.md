## Setup

```yaml
dependencies:
  tekartik_firebase_storage_node:
    git:
      url: git://github.com/tekartik/firebase_storage.dart
      path: storage_node
      ref: dart2
    version: '>=0.4.0'
```

## Test setup

 Use dart2 and set env variable
    
    npm install
    
 Update to latest node package
 
    npm install --save @google-cloud/storage
    
## Test

    pub run build_runner test -- -p node
    pub run test -p node
    pub run test -p node test/firestore_node_test.dart

### Single test

    pub run build_runner test -- -p node .\test\firestore_node_test.dart

    pbr test -- -p -node test/storage_node_test.dart
    pbr test -- -p -node test/firestore_node_test.dart
    pbr test -- -p -node test/admin_node_test.dart