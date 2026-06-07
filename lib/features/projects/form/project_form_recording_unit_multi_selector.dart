import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import 'project_form_models.dart';
import 'recording_unit_option.dart';

/// Sélection multiple d’UE du même projet (hors UE courante).
class ProjectFormRecordingUnitMultiSelector extends StatefulWidget {
  const ProjectFormRecordingUnitMultiSelector({
    super.key,
    required this.field,
    required this.loadOptions,
    required this.selected,
    required this.onChanged,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final Future<RecordingUnitOptionsLoad> Function() loadOptions;
  final List<RecordingUnitOption> selected;
  final ValueChanged<List<RecordingUnitOption>> onChanged;
  final bool isRequired;

  @override
  State<ProjectFormRecordingUnitMultiSelector> createState() =>
      ProjectFormRecordingUnitMultiSelectorState();
}

class ProjectFormRecordingUnitMultiSelectorState
    extends State<ProjectFormRecordingUnitMultiSelector> {
  final _filterController = TextEditingController();

  List<RecordingUnitOption> _allOptions = const [];
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
      final result = await widget.loadOptions();
      if (!mounted) return;
      setState(() {
        _allOptions = result.options;
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

  void updateOptions(List<RecordingUnitOption> options, {bool fromCache = false}) {
    if (!mounted) return;
    setState(() {
      _allOptions = options;
      _fromCache = fromCache;
    });
  }

  List<RecordingUnitOption> get _filteredOptions {
    final q = _filterController.text.trim().toLowerCase();
    if (q.isEmpty) return _allOptions;
    return _allOptions
        .where(
          (o) =>
              o.label.toLowerCase().contains(q) ||
              (o.typeLabel?.toLowerCase().contains(q) ?? false) ||
              (o.identifier?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  bool _isSelected(RecordingUnitOption option) {
    return widget.selected.any(
      (s) => RecordingUnitOption.refersToSameUnit(s, option),
    );
  }

  List<RecordingUnitOption> _nextSelection(
    RecordingUnitOption option,
    bool selected,
  ) {
    if (selected) {
      if (_isSelected(option)) return widget.selected;
      return [...widget.selected, option];
    }
    return widget.selected
        .where((s) => !RecordingUnitOption.refersToSameUnit(s, option))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<List<RecordingUnitOption>>(
      initialValue: widget.selected,
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Sélectionnez au moins une UE';
              }
              return null;
            }
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SiamoisSelectFieldLabel(
              label: widget.field.label,
              hint: widget.field.hint,
            ),
            if (widget.selected.isNotEmpty) ...[
              const SizedBox(height: SiamoisSpacing.sm),
              Wrap(
                spacing: SiamoisSpacing.xs,
                runSpacing: SiamoisSpacing.xs,
                children: widget.selected
                    .map(
                      (e) => SiamoisSelectChip(
                        label: e.display,
                        subtitle: e.typeLabel,
                        onDeleted: () {
                          final next = _nextSelection(e, false);
                          widget.onChanged(next);
                          state.didChange(next);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: SiamoisSpacing.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: SiamoisSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loadError != null)
              Column(
                children: [
                  Text(
                    _loadError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: SiamoisSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                  ),
                ],
              )
            else ...[
              if (_fromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: SiamoisSpacing.xs),
                  child: Text(
                    'Liste issue du cache local (hors ligne possible).',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: SiamoisColors.textSecondary,
                    ),
                  ),
                ),
              TextField(
                controller: _filterController,
                decoration: SiamoisFieldDecoration.forField(
                  label: 'Filtrer les UE du projet',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SiamoisColors.textTertiary,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: SiamoisSpacing.xs),
              SiamoisSelectSuggestionsPanel(
                emptyMessage: _allOptions.isEmpty
                    ? 'Aucune autre UE disponible dans ce projet.'
                    : _filteredOptions.isEmpty
                        ? 'Aucune UE ne correspond au filtre.'
                        : null,
                header: _filteredOptions.isNotEmpty
                    ? '${_filteredOptions.length} unité(s)'
                    : null,
                maxHeight: 240,
                children: _filteredOptions
                    .map(
                      (option) => SiamoisSelectCheckboxRow(
                        key: ValueKey(option.key),
                        label: option.label,
                        subtitle: option.typeLabel,
                        value: _isSelected(option),
                        onChanged: (v) {
                          final next = _nextSelection(option, v == true);
                          widget.onChanged(next);
                          state.didChange(next);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: SiamoisSpacing.xs),
                child: Text(
                  state.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
