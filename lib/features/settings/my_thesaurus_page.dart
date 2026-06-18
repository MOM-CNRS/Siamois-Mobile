import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' hide Form;
import '../auth/auth_repository.dart';
import 'thesaurus_config_page.dart';
import 'thesaurus_settings_scope.dart';

/// Configuration du thésaurus personnel (équivalent web « Mon thésaurus »).
class MyThesaurusPage extends StatelessWidget {
  const MyThesaurusPage({
    super.key,
    required this.auth,
    required this.database,
  });

  final AuthRepository auth;
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final orgId = auth.primaryOrganizationId;
    if (orgId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon thésaurus')),
        body: const Center(
          child: Text('Organisation introuvable. Reconnectez-vous.'),
        ),
      );
    }

    final orgName = auth.userProfile?.primaryOrganizationName?.trim();
    return ThesaurusConfigPage(
      auth: auth,
      database: database,
      scope: ThesaurusSettingsScope.user,
      organisationId: orgId,
      organisationName: orgName?.isNotEmpty == true
          ? orgName!
          : 'Organisation $orgId',
      pageTitle: 'Mon thésaurus',
      heading: 'Gestion de mon thésaurus',
      infoMessage:
          'Renseignez le lien permanent vers votre thésaurus OpenTheso. '
          'Siamois importera les concepts nécessaires aux listes déroulantes '
          '(catégories, types, etc.) pour votre compte.',
    );
  }
}
