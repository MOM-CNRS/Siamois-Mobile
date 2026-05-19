import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../pages/create_project_page.dart';
import '../project_models.dart';

/// Ouvre l’écran de création de projet (formulaire dynamique).
Future<ProjectSummary?> openCreateProjectFlow({
  required BuildContext context,
  required AuthRepository auth,
  required AppDatabase database,
}) {
  return Navigator.of(context).push<ProjectSummary>(
    MaterialPageRoute(
      builder: (_) => CreateProjectPage(
        auth: auth,
        database: database,
      ),
    ),
  );
}
