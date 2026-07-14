import 'package:flutter/foundation.dart';

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
    if (row == null) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Vocab] Lecture cache SQLite org $organisationId — '
          'aucune entrée vocabulaire.',
        );
      }
      return const {};
    }

    final map = db.decodeFormMap(row);
    final data = map?['data'];
    if (data is! Map) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Vocab] Lecture cache SQLite org $organisationId — '
          'contenu illisible (pas de clé data).',
        );
      }
      return const {};
    }

    final vocabs = data['vocabulariesByFieldCode'];
    if (vocabs is! Map) {
      if (kDebugMode) {
        debugPrint(
          '[Siamois Vocab] Lecture cache SQLite org $organisationId — '
          'vocabulariesByFieldCode absent.',
        );
      }
      return const {};
    }

    final parsed = ConceptOption.vocabulariesFromApiMap(
      Map<String, dynamic>.from(vocabs),
    );

    if (kDebugMode) {
      final diagnostic = VocabularyDiagnostic.fromVocabByCode(parsed);
      debugPrint(
        '[Siamois Vocab] Lecture cache SQLite org $organisationId — '
        '${diagnostic.summary}',
      );
      for (final line in diagnostic.detailLines) {
        debugPrint('[Siamois Vocab]   $line');
      }
    }

    return parsed;
  }
}
