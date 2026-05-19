import 'package:flutter/material.dart';

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

  /// Met à jour la liste après synchronisation réseau en arrière-plan.
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
            Text(
              widget.field.label,
              style: theme.textTheme.titleSmall,
            ),
            if (widget.field.hint != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.field.hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (widget.selected.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selected
                    .map(
                      (e) => InputChip(
                        label: Text(
                          e.display,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          final next = _nextSelection(e, false);
                          widget.onChanged(next);
                          state.didChange(next);
                        },
                      ),
                    )
                    .toList(),
              ),
            if (widget.selected.isNotEmpty) const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: 8),
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
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Liste issue du cache local (hors ligne possible).',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              TextField(
                controller: _filterController,
                decoration: const InputDecoration(
                  labelText: 'Filtrer les UE du projet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (_allOptions.isEmpty)
                Text(
                  'Aucune autre UE disponible dans ce projet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filteredOptions[index];
                      final checked = _isSelected(option);
                      return CheckboxListTile(
                        key: ValueKey(option.key),
                        value: checked,
                        onChanged: (v) {
                          final next = _nextSelection(option, v == true);
                          widget.onChanged(next);
                          state.didChange(next);
                        },
                        title: Text(option.label),
                        subtitle: option.typeLabel != null
                            ? Text(option.typeLabel!)
                            : null,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
            ],
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
