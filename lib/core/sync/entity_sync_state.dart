/// État de synchronisation affiché sur une carte entité.
enum EntitySyncState {
  synced,
  pending,
  error,
}

extension EntitySyncStateX on EntitySyncState {
  bool get needsSyncIndicator =>
      this == EntitySyncState.pending || this == EntitySyncState.error;
}
