/// Client side of a storage hosted by a firebase sim server:
/// `storageServiceSim.storage(app)` on a `FirebaseAppSim`
/// (`getFirebaseSim`) forwards every bucket and file call to the server.
library;

import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_client.dart'
    as impl;

/// Storage service simulation.
StorageService get storageServiceSim => impl.storageServiceSim;
