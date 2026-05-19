import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../vocabulary_models.dart';
import 'project_form_models.dart';

export 'project_form_date_input.dart';

class ProjectFormTextInput extends StatelessWidget {
  const ProjectFormTextInput({
    super.key,
    required this.field,
    required this.controller,
    this.validator,
  });

  final ProjectFormField field;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isInteger = field.isIntegerInput;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isInteger ? TextInputType.number : TextInputType.text,
      inputFormatters: isInteger
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      textCapitalization: isInteger
          ? TextCapitalization.none
          : field.valueBinding == 'name'
              ? TextCapitalization.sentences
              : TextCapitalization.none,
      autocorrect: !isInteger && field.valueBinding != 'identifier',
      validator: validator ??
          _defaultValidator(field, isInteger: isInteger),
    );
  }

  String? Function(String?)? _defaultValidator(
    ProjectFormField field, {
    required bool isInteger,
  }) {
    if (isInteger) {
      return (v) {
        final trimmed = v?.trim() ?? '';
        if (field.isRequired && trimmed.isEmpty) {
          return '« ${field.label} » est obligatoire';
        }
        if (trimmed.isNotEmpty && int.tryParse(trimmed) == null) {
          return '« ${field.label} » doit être un nombre entier';
        }
        return null;
      };
    }
    if (field.isRequired) {
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return '« ${field.label} » est obligatoire';
        }
        return null;
      };
    }
    return null;
  }
}

class ProjectFormConceptDropdown extends StatelessWidget {
  const ProjectFormConceptDropdown({
    super.key,
    required this.field,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final ProjectFormField field;
  final List<ConceptOption> options;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final menuOptions = List<ConceptOption>.from(options);
    if (value != null && !menuOptions.any((o) => o.id == value)) {
      menuOptions.insert(
        0,
        ConceptOption(
          id: value!,
          label: 'Valeur enregistrée (ID $value)',
        ),
      );
    }

    final selectedValue = value != null &&
            menuOptions.any((o) => o.id == value)
        ? value
        : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('concept_${field.fieldId}_$selectedValue'),
      value: selectedValue,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.hint,
        border: const OutlineInputBorder(),
      ),
      items: menuOptions
          .map(
            (o) => DropdownMenuItem(
              value: o.id,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: field.isRequired
          ? (_) =>
              selectedValue == null ? '« ${field.label} » est obligatoire' : null
          : null,
    );
  }
}

class ProjectFormSpatialAutocomplete extends StatefulWidget {
  const ProjectFormSpatialAutocomplete({
    super.key,
    required this.field,
    required this.organizationId,
    required this.search,
    this.value,
    required this.onChanged,
  });

  final ProjectFormField field;
  final int organizationId;
  final Future<List<SpatialUnitOption>> Function(String query) search;
  final SpatialUnitOption? value;
  final ValueChanged<SpatialUnitOption?> onChanged;

  @override
  State<ProjectFormSpatialAutocomplete> createState() =>
      _ProjectFormSpatialAutocompleteState();
}

class _ProjectFormSpatialAutocompleteState
    extends State<ProjectFormSpatialAutocomplete> {
  final _controller = TextEditingController();
  List<SpatialUnitOption> _suggestions = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.value != null) {
      _controller.text = widget.value!.display;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await widget.search(query);
      if (mounted) setState(() => _suggestions = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.field.label,
            helperText: widget.field.hint ?? 'Saisissez au moins 2 caractères',
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
                          _controller.clear();
                          setState(() => _suggestions = const []);
                        },
                      )
                    : const Icon(Icons.search_rounded)),
          ),
          onChanged: _runSearch,
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
                  title: Text(item.label),
                  subtitle: item.code != null ? Text(item.code!) : null,
                  onTap: () {
                    widget.onChanged(item);
                    _controller.text = item.display;
                    setState(() => _suggestions = const []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class ProjectFormSpatialMultiSelector extends StatefulWidget {
  const ProjectFormSpatialMultiSelector({
    super.key,
    required this.field,
    required this.search,
    required this.selected,
    required this.onChanged,
  });

  final ProjectFormField field;
  final Future<List<SpatialUnitOption>> Function(String query) search;
  final List<SpatialUnitOption> selected;
  final ValueChanged<List<SpatialUnitOption>> onChanged;

  @override
  State<ProjectFormSpatialMultiSelector> createState() =>
      _ProjectFormSpatialMultiSelectorState();
}

class _ProjectFormSpatialMultiSelectorState
    extends State<ProjectFormSpatialMultiSelector> {
  final _searchController = TextEditingController();
  List<SpatialUnitOption> _suggestions = const [];
  bool _loading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await widget.search(query);
      if (mounted) setState(() => _suggestions = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _add(SpatialUnitOption item) {
    if (widget.selected.any((e) => e.id == item.id)) return;
    widget.onChanged([...widget.selected, item]);
    _searchController.clear();
    setState(() => _suggestions = const []);
  }

  void _remove(int id) {
    widget.onChanged(widget.selected.where((e) => e.id != id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.field.label, style: Theme.of(context).textTheme.titleSmall),
        if (widget.field.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.field.hint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.selected
              .map(
                (e) => InputChip(
                  label: Text(e.display, overflow: TextOverflow.ellipsis),
                  onDeleted: () => _remove(e.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Rechercher un lieu',
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
                : const Icon(Icons.search_rounded),
          ),
          onChanged: _runSearch,
        ),
        if (_suggestions.isNotEmpty)
          ..._suggestions.map(
            (item) => ListTile(
              dense: true,
              title: Text(item.label),
              subtitle: item.code != null ? Text(item.code!) : null,
              trailing: widget.selected.any((e) => e.id == item.id)
                  ? const Icon(Icons.check_rounded)
                  : const Icon(Icons.add_rounded),
              onTap: () => _add(item),
            ),
          ),
      ],
    );
  }
}
