import 'package:flutter/material.dart';

import 'person_directory_store.dart';
import 'person_option.dart';
import 'project_form_models.dart';

/// Autocomplétion personne (sélection unique).
class ProjectFormPersonAutocomplete extends StatefulWidget {
  const ProjectFormPersonAutocomplete({
    super.key,
    required this.field,
    required this.directory,
    required this.organizationId,
    this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final PersonDirectoryStore directory;
  final int organizationId;
  final PersonOption? value;
  final ValueChanged<PersonOption?> onChanged;
  final bool isRequired;

  @override
  State<ProjectFormPersonAutocomplete> createState() =>
      _ProjectFormPersonAutocompleteState();
}

class _ProjectFormPersonAutocompleteState
    extends State<ProjectFormPersonAutocomplete> {
  final _controller = TextEditingController();
  List<PersonOption> _suggestions = const [];
  bool _loading = false;
  bool _fromCache = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!.display;
    }
  }

  @override
  void didUpdateWidget(covariant ProjectFormPersonAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value?.display ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    try {
      final result = await widget.directory.search(
        organizationId: widget.organizationId,
        query: q,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = result.items;
        _fromCache = result.fromCache;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<PersonOption>(
      initialValue: widget.value,
      validator: widget.isRequired
          ? (v) => v == null ? '« ${widget.field.label} » est obligatoire' : null
          : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: widget.field.label,
                helperText: widget.field.hint ??
                    'Recherchez une personne de l’organisation',
                border: const OutlineInputBorder(),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (widget.value != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              widget.onChanged(null);
                              state.didChange(null);
                              _controller.clear();
                              setState(() => _suggestions = const []);
                            },
                          )
                        : const Icon(Icons.person_search_rounded)),
              ),
              onChanged: _runSearch,
              onTap: () {
                if (_suggestions.isEmpty) _runSearch(_controller.text);
              },
            ),
            if (_fromCache && _suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Annuaire local (hors ligne possible).',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_suggestions.isNotEmpty)
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(item.display),
                      onTap: () {
                        widget.onChanged(item);
                        state.didChange(item);
                        _controller.text = item.display;
                        setState(() => _suggestions = const []);
                      },
                    );
                  },
                ),
              ),
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

/// Sélection multiple de personnes.
class ProjectFormPersonMultiSelector extends StatefulWidget {
  const ProjectFormPersonMultiSelector({
    super.key,
    required this.field,
    required this.directory,
    required this.organizationId,
    required this.selected,
    required this.onChanged,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final PersonDirectoryStore directory;
  final int organizationId;
  final List<PersonOption> selected;
  final ValueChanged<List<PersonOption>> onChanged;
  final bool isRequired;

  @override
  State<ProjectFormPersonMultiSelector> createState() =>
      _ProjectFormPersonMultiSelectorState();
}

class _ProjectFormPersonMultiSelectorState
    extends State<ProjectFormPersonMultiSelector> {
  final _filterController = TextEditingController();
  List<PersonOption> _options = const [];
  bool _loading = true;
  bool _fromCache = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await widget.directory.search(
        organizationId: widget.organizationId,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _options = result.items;
        _fromCache = result.fromCache;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  bool _isSelected(PersonOption person) {
    return widget.selected.any((s) => s.id == person.id);
  }

  List<PersonOption> _nextSelection(PersonOption person, bool selected) {
    if (selected) {
      if (_isSelected(person)) return widget.selected;
      return [...widget.selected, person];
    }
    return widget.selected.where((s) => s.id != person.id).toList();
  }

  List<PersonOption> get _filteredOptions {
    final q = _filterController.text.trim().toLowerCase();
    if (q.isEmpty) return _options;
    return _options
        .where(
          (p) =>
              p.display.toLowerCase().contains(q) ||
              (p.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<List<PersonOption>>(
      initialValue: widget.selected,
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Sélectionnez au moins une personne';
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
                    onPressed: () => _load(_filterController.text),
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
                    'Annuaire local (hors ligne possible).',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              TextField(
                controller: _filterController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher une personne',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (q) {
                  setState(() {});
                  _load(q);
                },
              ),
              const SizedBox(height: 8),
              if (_filteredOptions.isEmpty)
                Text(
                  'Aucune personne trouvée.',
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
                        value: checked,
                        onChanged: (v) {
                          final next = _nextSelection(option, v == true);
                          widget.onChanged(next);
                          state.didChange(next);
                        },
                        title: Text(option.display),
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
