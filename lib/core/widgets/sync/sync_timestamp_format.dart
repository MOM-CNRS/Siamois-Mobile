import 'package:intl/intl.dart';

/// Libellé français pour la dernière synchronisation réussie.
String formatLastSyncTimestamp(DateTime? at) {
  if (at == null) return 'Jamais synchronisé';
  return DateFormat("dd/MM/yyyy 'à' HH:mm", 'fr_FR').format(at.toLocal());
}
