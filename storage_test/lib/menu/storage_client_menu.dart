import 'dart:convert';

import 'package:path/path.dart';
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
  var bucket = context.storage.bucket(context.bucket);
  var rootPath = context.rootPath;

  String fixPath(String path) =>
      rootPath != null ? url.join(rootPath, path) : path;
  var testFile = bucket.file(fixPath('file0.txt'));
  menu('bucket', () {
    item('list_files', () async {
      var files = await bucket.getFiles(GetFilesOptions(prefix: rootPath));
      write('${files.files.length} files found');
      for (var file in files.files) {
        write('name: ${file.name}');
        write('metadata: ${file.metadata}');
      }
    });
    item('write_file', () async {
      await testFile.upload(
        utf8.encode('hello'),
        options: StorageUploadFileOptions(contentType: 'text/plain'),
      );
    });
    item('delete_file', () async {
      await testFile.delete();
    });
    item('read_file', () async {
      var content = await testFile.readAsBytes();
      print('content: ${utf8.decode(content)}');
    });
    item('read_metadata', () async {
      var metadata = await testFile.getMetadata();
      print('metadata: $metadata');
    });
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
