import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_repository.dart';
import '../form/recording_unit_option.dart';
import 'recording_unit_list_store.dart';

/// Sélection d’une UE existante du projet (parent ou enfant).
abstract final class RecordingUnitProjectPicker {
  static Future<RecordingUnitOption?> show(
    BuildContext context, {
    required AuthRepository auth,
    required AppDatabase database,
    required String projectId,
    required String title,
    required List<RecordingUnitOption> excludeOptions,
    String? excludeRecordingUnitId,
  }) {
    return showDialog<RecordingUnitOption>(
      context: context,
      builder: (ctx) => _RecordingUnitProjectPickerDialog(
        auth: auth,
        database: database,
        projectId: projectId,
        title: title,
        excludeOptions: RecordingUnitOption.dedupe(excludeOptions),
        excludeRecordingUnitId: excludeRecordingUnitId,
      ),
    );
  }
}

class _RecordingUnitProjectPickerDialog extends StatefulWidget {
  const _RecordingUnitProjectPickerDialog({
    required this.auth,
    required this.database,
    required this.projectId,
    required this.title,
    required this.excludeOptions,
    this.excludeRecordingUnitId,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String projectId;
  final String title;
  final List<RecordingUnitOption> excludeOptions;
  final String? excludeRecordingUnitId;

  @override
  State<_RecordingUnitProjectPickerDialog> createState() =>
      _RecordingUnitProjectPickerDialogState();
}

class _RecordingUnitProjectPickerDialogState
    extends State<_RecordingUnitProjectPickerDialog> {
  final _filterController = TextEditingController();

  List<RecordingUnitOption> _options = const [];
  String? _loadError;
  bool _loading = true;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await RecordingUnitListStore(
        auth: widget.auth,
        db: widget.database,
      ).loadAllForPicker(
        widget.projectId,
        excludeRecordingUnitId: widget.excludeRecordingUnitId,
      );
      if (!mounted) return;
      setState(() {
        _options = result.items
            .map(RecordingUnitOption.fromItem)
            .where((o) => !_isExcluded(o))
            .toList();
        _loading = false;
        _fromCache = result.fromCache;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  bool _isExcluded(RecordingUnitOption option) {
    return RecordingUnitOption.listContainsUnit(widget.excludeOptions, option);
  }

  List<RecordingUnitOption> get _filtered {
    final q = _filterController.text.trim().toLowerCase();
    if (q.isEmpty) return _options;
    return _options
        .where(
          (o) =>
              o.label.toLowerCase().contains(q) ||
              (o.typeLabel?.toLowerCase().contains(q) ?? false) ||
              (o.identifier?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null) ...[
              Text(
                _loadError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: SiamoisSpacing.sm),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ] else ...[
              if (_fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: SiamoisSpacing.xs),
                  child: Text(
                    'Liste issue du cache local.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: SiamoisColors.textSecondary,
                    ),
                  ),
                ),
              TextField(
                controller: _filterController,
                autofocus: true,
                decoration: SiamoisFieldDecoration.forField(
                  label: 'Rechercher une UE',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SiamoisColors.textTertiary,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: SiamoisSpacing.sm),
              SiamoisSelectSuggestionsPanel(
                emptyMessage: _options.isEmpty
                    ? 'Aucune autre UE disponible dans ce projet.'
                    : filtered.isEmpty
                        ? 'Aucune UE ne correspond au filtre.'
                        : null,
                header: filtered.isNotEmpty
                    ? '${filtered.length} unité(s)'
                    : null,
                maxHeight: 320,
                children: filtered
                    .map(
                      (option) => SiamoisSelectSuggestionTile(
                        key: ValueKey(option.key),
                        title: option.label,
                        subtitle: option.typeLabel,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: SiamoisColors.textTertiary,
                        ),
                        onTap: () => Navigator.of(context).pop(option),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
