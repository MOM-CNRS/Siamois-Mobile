import 'package:flutter/material.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
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
    this.directoryById,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final PersonDirectoryStore directory;
  final int organizationId;
  final PersonOption? value;
  final ValueChanged<PersonOption?> onChanged;
  final Map<int, PersonOption>? directoryById;
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

  String _labelFor(PersonOption? person) {
    if (person == null) return '';
    final resolved =
        PersonOption.resolve(person, directoryById: widget.directoryById);
    if (resolved != null && resolved.hasDisplayName) {
      return resolved.display;
    }
    return person.display;
  }

  @override
  void initState() {
    super.initState();
    _controller.text = _labelFor(widget.value);
  }

  @override
  void didUpdateWidget(covariant ProjectFormPersonAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value ||
        widget.directoryById != oldWidget.directoryById) {
      _controller.text = _labelFor(widget.value);
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
              decoration: SiamoisFieldDecoration.forField(
                label: widget.field.label,
                hint: widget.field.hint ??
                    'Recherchez une personne de l’organisation',
                suffixIcon: _loading
                    ? SiamoisFieldDecoration.loadingSuffix()
                    : SiamoisFieldDecoration.clearSuffix(
                        visible: widget.value != null,
                        onClear: () {
                          widget.onChanged(null);
                          state.didChange(null);
                          _controller.clear();
                          setState(() => _suggestions = const []);
                        },
                      ) ??
                        SiamoisFieldDecoration.personSearchSuffix(),
              ),
              onChanged: _runSearch,
              onTap: () {
                if (_suggestions.isEmpty) _runSearch(_controller.text);
              },
            ),
            if (_fromCache && _suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SiamoisSpacing.xxs),
                child: Text(
                  'Annuaire local (hors ligne possible).',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: SiamoisColors.textSecondary,
                  ),
                ),
              ),
            SiamoisSelectSuggestionsPanel(
              header: _suggestions.isNotEmpty ? 'Personnes' : null,
              children: _suggestions
                  .map(
                    (item) => SiamoisSelectSuggestionTile(
                      title: item.display,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: SiamoisColors.primaryContainer,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: SiamoisColors.primary,
                        ),
                      ),
                      onTap: () {
                        widget.onChanged(item);
                        state.didChange(item);
                        _controller.text = item.display;
                        setState(() => _suggestions = const []);
                      },
                    ),
                  )
                  .toList(),
            ),
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

/// Sélection multiple de personnes.
class ProjectFormPersonMultiSelector extends StatefulWidget {
  const ProjectFormPersonMultiSelector({
    super.key,
    required this.field,
    required this.directory,
    required this.organizationId,
    required this.selected,
    required this.onChanged,
    this.directoryById,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final PersonDirectoryStore directory;
  final int organizationId;
  final List<PersonOption> selected;
  final ValueChanged<List<PersonOption>> onChanged;
  final Map<int, PersonOption>? directoryById;
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

  String _labelFor(PersonOption person) {
    final resolved =
        PersonOption.resolve(person, directoryById: widget.directoryById);
    if (resolved != null && resolved.hasDisplayName) {
      return resolved.display;
    }
    return person.display;
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
    return _options.where((p) => p.matchesQuery(q)).toList();
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
                        label: _labelFor(e),
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
                    onPressed: () => _load(_filterController.text),
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
                    'Annuaire local (hors ligne possible).',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: SiamoisColors.textSecondary,
                    ),
                  ),
                ),
              TextField(
                controller: _filterController,
                decoration: SiamoisFieldDecoration.forField(
                  label: 'Rechercher une personne',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SiamoisColors.textTertiary,
                  ),
                ),
                onChanged: (q) {
                  setState(() {});
                  _load(q);
                },
              ),
              const SizedBox(height: SiamoisSpacing.xs),
              SiamoisSelectSuggestionsPanel(
                emptyMessage: _filteredOptions.isEmpty
                    ? 'Aucune personne trouvée.'
                    : null,
                header: _filteredOptions.isNotEmpty
                    ? '${_filteredOptions.length} personne(s)'
                    : null,
                maxHeight: 240,
                children: _filteredOptions
                    .map(
                      (option) => SiamoisSelectCheckboxRow(
                        label: _labelFor(option),
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
