import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siamois_mobile/core/database/app_database.dart';
import 'package:siamois_mobile/core/database/local_auth_store.dart';

void main() {
  test('le login enregistre les organisations aux ids en chaîne', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = LocalAuthStore(db);

    await store.saveFromLoginResponse(
      loginJson: {
        'user': {
          'name': 'Ada',
          'lastname': 'L',
          'email': 'ada@example.org',
          'organizations': [
            {'id': '1', 'name': 'Org A'},
            {'id': 2, 'name': 'Org B'},
          ],
        },
      },
      email: 'ada@example.org',
      password: 'x',
    );

    final orgs = await db.select(db.organisations).get();
    expect(orgs.map((o) => o.id), unorderedEquals([1, 2]));
  });
}
