import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/siamois_colors.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
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
      decoration: SiamoisFieldDecoration.forField(
        label: field.label,
        hint: field.hint,
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

    return SiamoisSelectDropdown<int>(
      key: ValueKey('concept_${field.fieldId}_$selectedValue'),
      label: field.label,
      hint: field.hint,
      value: selectedValue,
      hintText: 'Choisir…',
      items: menuOptions
          .map(
            (o) => DropdownMenuItem(
              value: o.id,
              child: Text(
                o.label,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
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
          decoration: SiamoisFieldDecoration.forField(
            label: widget.field.label,
            hint: widget.field.hint ?? 'Saisissez au moins 2 caractères',
            suffixIcon: _loading
                ? SiamoisFieldDecoration.loadingSuffix()
                : SiamoisFieldDecoration.clearSuffix(
                    visible: widget.value != null,
                    onClear: () {
                      widget.onChanged(null);
                      _controller.clear();
                      setState(() => _suggestions = const []);
                    },
                  ) ??
                    SiamoisFieldDecoration.searchSuffix(),
          ),
          onChanged: _runSearch,
        ),
        SiamoisSelectSuggestionsPanel(
          header: _suggestions.isNotEmpty ? 'Résultats' : null,
          children: _suggestions
              .map(
                (item) => SiamoisSelectSuggestionTile(
                  title: item.label,
                  subtitle: item.code,
                  leading: const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: SiamoisColors.primary,
                  ),
                  onTap: () {
                    widget.onChanged(item);
                    _controller.text = item.display;
                    setState(() => _suggestions = const []);
                  },
                ),
              )
              .toList(),
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
                    subtitle: e.code,
                    onDeleted: () => _remove(e.id),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: SiamoisSpacing.sm),
        TextField(
          controller: _searchController,
          decoration: SiamoisFieldDecoration.forField(
            label: 'Rechercher un lieu',
            hint: 'Au moins 2 caractères',
            suffixIcon: SiamoisFieldDecoration.searchSuffix(loading: _loading),
          ),
          onChanged: _runSearch,
        ),
        SiamoisSelectSuggestionsPanel(
          header: _suggestions.isNotEmpty ? 'Ajouter un lieu' : null,
          children: _suggestions.map((item) {
            final already = widget.selected.any((e) => e.id == item.id);
            return SiamoisSelectSuggestionTile(
              title: item.label,
              subtitle: item.code,
              selected: already,
              leading: Icon(
                already ? Icons.check_circle_rounded : Icons.add_circle_outline,
                size: 20,
                color: already
                    ? SiamoisColors.success
                    : SiamoisColors.primary,
              ),
              onTap: already ? () {} : () => _add(item),
            );
          }).toList(),
        ),
      ],
    );
  }
}
