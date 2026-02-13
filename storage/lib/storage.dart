/// Exports core Firebase functionality for authentication and app initialization.
library;

export 'package:tekartik_firebase/firebase.dart';

/// Exports the main Firebase Storage API abstractions.
///
/// This library provides an abstraction over Firebase Storage, enabling
/// operations such as uploading, downloading, and managing files in cloud storage.
/// It includes classes for interacting with storage buckets, references, and files.
///
/// Key exports:
/// - [FirebaseStorage]: The main entry point for Firebase Storage operations.
/// - [Storage]: Interface for storage services.
/// - [Bucket]: Represents a storage bucket.
/// - [Reference]: A reference to a file or directory in storage.
/// - [File]: Represents a file in storage.
/// - [FileMetadata]: Metadata associated with a file.
/// - [StorageUploadFileOptions]: Options for uploading files.
/// - [GetFilesOptions] and [GetFilesResponse]: For listing files.
/// - Mixins like [FirebaseStorageMixin], [StorageMixin], etc., provide implementation details.
export 'package:tekartik_firebase_storage/src/storage.dart'
    show
        FirebaseStorage,
        Storage,
        FirebaseStorageMixin,
        StorageMixin,
        Bucket,
        BucketMixin,
        StorageUploadFileOptions,
        Reference,
        ReferenceMixin,
        File,
        FileMixin,
        FileMetadata,
        FileMetadataMixin,
        FirebaseStorageService,
        StorageService,
        GetFilesOptions,
        GetFilesResponse;
