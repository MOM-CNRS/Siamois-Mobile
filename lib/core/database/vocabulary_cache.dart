import 'app_database.dart';
import '../../features/projects/vocabulary_models.dart';
import 'tables.dart';

/// Vocabulaires (`forms` type `vocabulaire`) depuis SQLite.
abstract final class VocabularyCache {
  static Future<Map<String, List<ConceptOption>>> loadByFieldCode(
    AppDatabase db, {
    required int organisationId,
  }) async {
    final row = await db.findCachedForm(
      organisationId: organisationId,
      type: FormCacheType.vocabulaire,
    );
    if (row == null) return const {};

    final map = db.decodeFormMap(row);
    final data = map?['data'];
    if (data is! Map) return const {};

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) return const {};

    return ConceptOption.vocabulariesFromApiMap(
      Map<String, dynamic>.from(vocabs),
    );
  }
}
