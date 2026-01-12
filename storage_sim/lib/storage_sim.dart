import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_firebase_storage_sim/src/storage_sim_client.dart'
    as impl;

/// Storage service simulation.
StorageService get storageServiceSim => impl.storageServiceSim;
