/// Identifiants locaux négatifs pour les lieux créés hors ligne.
abstract final class SpatialUnitLocalId {
  static bool isLocalId(int id) => id < 0;
}
