import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_browser/src/storage_browser.dart'
    as impl;

export 'package:tekartik_firebase_storage_browser/src/storage_browser.dart'
    show storageService;

/// Browser service
///
/// NOT IMPLEMENTED
StorageService get storageServiceBrowser => impl.storageService;
