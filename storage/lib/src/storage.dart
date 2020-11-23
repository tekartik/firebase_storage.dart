import 'dart:async';
import 'dart:typed_data';
import 'package:tekartik_firebase/firebase.dart';

/// Query object for listing files.
class GetFilesOptions {
  final int maxResults;
  final String prefix;
  final bool autoPaginate;
  final String pageToken;

  GetFilesOptions(
      {this.maxResults, this.prefix, this.pageToken, this.autoPaginate = true});

  @override
  String toString() => {
        if (maxResults != null) 'maxResults': maxResults,
        if (prefix != null) 'prefix': prefix,
        'autoPaginate': autoPaginate,
        if (pageToken != null) 'pageToken': pageToken
      }.toString();
}

/// GetFiles response
abstract class GetFilesResponse {
  List<File> get files;
  GetFilesOptions get nextQuery;
}

class StorageMixin {}

abstract class Storage {
  Bucket bucket([String name]);
}

abstract class Bucket {
  String get name;
  File file(String path);
  Future<bool> exists();
}

abstract class File {
  Future save(/* String | List<int> */ dynamic content);
  Future<bool> exists();
  Future<Uint8List> download();
  Future delete();

  /// Name of the remote file
  String get name;

  /// The bucket instance the is attached to.
  Bucket get bucket;
}

abstract class StorageService {
  Storage storage(App app);
}
