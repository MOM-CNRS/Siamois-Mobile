import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../auth/auth_repository.dart';
import '../pages/project_detail_page.dart';
import '../project_models.dart';

Future<bool?> openProjectDetail({
  required BuildContext context,
  required AuthRepository auth,
  required AppDatabase database,
  required ProjectSummary project,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ProjectDetailPage(
        auth: auth,
        database: database,
        projectId: project.storageId,
        summary: project,
      ),
    ),
  );
}
