import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_storage/storage.dart';

export 'package:tekartik_app_dev_menu/dev_menu.dart';
export 'package:tekartik_firebase_storage/storage.dart';

/// Top doc context
class StorageMainMenuContext {
  final FirebaseStorage storage;
  final String? bucket;
  final String? rootPath;

  StorageMainMenuContext({required this.storage, this.bucket, this.rootPath});
}

void firebaseStorageMainMenu({required StorageMainMenuContext context}) {
  menu('bucket', () {
    /*
    StreamSubscription? subscription;
    var coll = context.doc.collection('change');
    item('register changes', () {
      subscription?.cancel();
      subscription = coll.onSnapshotSupport().listen((event) {
        write('onItems: ${event.docs.length}');
        for (var item in event.docs) {
          write('- $item');
        }
      });
    });
    item('cancel registration', () {
      subscription?.cancel();
    });
    item('add item', () async {
      await coll.add({'test': Timestamp.now()});
    });
    item('clear', () async {
      await deleteCollection(context.firestore, coll);
    });
    item('list', () async {
      var list = await coll.get();
      for (var item in list.docs) {
        write('item: $item');
      }
    });
  });
  menu('singleton', () {
    StreamSubscription? subscription;
    var doc = context.doc.collection('changes').doc('singleton');
    item('register changes', () {
      subscription?.cancel();
      subscription = doc.onSnapshotSupport().listen((event) {
        var now = Timestamp.now();
        var eventTimestamp = (event.data['timestamp'] as Timestamp?) ?? now;
        write(
          'diff: ${now.millisecondsSinceEpoch - eventTimestamp.millisecondsSinceEpoch} ms',
        );
        write('onItem: $event');
      });
    });
    item('cancel registration', () {
      subscription?.cancel();
    });
    item('set item', () async {
      await doc.set({'timestamp': Timestamp.now()});
    });
    item('delete', () async {
      await doc.delete();
    });
    item('get', () async {
      var item = await doc.get();
      write('item: $item');
    });*/
  });
}
