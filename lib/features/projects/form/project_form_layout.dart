import 'dart:convert';

import 'project_form_models.dart';

/// Colonne du layout (référence un champ par `fieldId`).
class ProjectFormLayoutColumn {
  const ProjectFormLayoutColumn({
    required this.fieldId,
    this.isRequired = false,
    this.isReadOnly = false,
  });

  final int fieldId;
  final bool isRequired;
  final bool isReadOnly;
}

/// Panneau du formulaire (section UI avec titre + champs ordonnés).
class ProjectFormPanelLayout {
  const ProjectFormPanelLayout({
    required this.nameKey,
    required this.displayTitle,
    required this.slots,
    this.isSystemPanel = false,
  });

  /// Clé i18n d’origine (`common.header.general`, etc.).
  final String nameKey;
  final String displayTitle;
  final List<ProjectFormFieldSlot> slots;
  final bool isSystemPanel;
}

/// Champ placé dans le layout avec métadonnées colonne.
class ProjectFormFieldSlot {
  const ProjectFormFieldSlot({
    required this.field,
    required this.isRequired,
    required this.isReadOnly,
  });

  final ProjectFormField field;
  final bool isRequired;
  final bool isReadOnly;
}

/// Parse `form.layoutJson` et associe les champs du map `fields`.
class ProjectFormLayoutParser {
  const ProjectFormLayoutParser._();

  static List<ProjectFormPanelLayout> parsePanels({
    required String? layoutJson,
    required Map<int, ProjectFormField> fieldsById,
  }) {
    if (layoutJson == null || layoutJson.trim().isEmpty) {
      return withIdentifierFirst(_singlePanelFallback(fieldsById));
    }

    try {
      final decoded = jsonDecode(layoutJson);
      if (decoded is! List) {
        return withIdentifierFirst(_singlePanelFallback(fieldsById));
      }

      final panels = <ProjectFormPanelLayout>[];
      final usedFieldIds = <int>{};

      for (final panelRaw in decoded) {
        if (panelRaw is! Map) continue;
        final panelMap = Map<String, dynamic>.from(panelRaw);
        final nameKey = (panelMap['name'] as String?)?.trim() ?? '';
        if (nameKey.isEmpty) continue;

        final slots = <ProjectFormFieldSlot>[];
        final rows = panelMap['rows'];
        if (rows is List) {
          for (final rowRaw in rows) {
            if (rowRaw is! Map) continue;
            final columns = rowRaw['columns'];
            if (columns is! List) continue;
            for (final colRaw in columns) {
              final slot = _slotFromColumn(colRaw, fieldsById);
              if (slot != null) {
                slots.add(slot);
                usedFieldIds.add(slot.field.fieldId);
              }
            }
          }
        }

        if (slots.isNotEmpty) {
          panels.add(
            ProjectFormPanelLayout(
              nameKey: nameKey,
              displayTitle: panelTitleFromKey(nameKey),
              slots: slots,
              isSystemPanel: panelMap['isSystemPanel'] == true,
            ),
          );
        }
      }

      final orphans = fieldsById.values
          .where((f) => !usedFieldIds.contains(f.fieldId))
          .toList()
        ..sort((a, b) => a.fieldId.compareTo(b.fieldId));

      if (orphans.isNotEmpty) {
        panels.add(
          ProjectFormPanelLayout(
            nameKey: 'autres',
            displayTitle: 'Autres',
            slots: orphans
                .map(
                  (f) => ProjectFormFieldSlot(
                    field: f,
                    isRequired: f.isRequired,
                    isReadOnly: false,
                  ),
                )
                .toList(),
          ),
        );
      }

      if (panels.isEmpty) {
        return withIdentifierFirst(_singlePanelFallback(fieldsById));
      }
      return withIdentifierFirst(panels);
    } catch (_) {
      return withIdentifierFirst(_singlePanelFallback(fieldsById));
    }
  }

  /// Place le(s) champ(s) « Identifiant » dans le panneau Général, et ce panneau en tête.
  static List<ProjectFormPanelLayout> withIdentifierFirst(
    List<ProjectFormPanelLayout> panels,
  ) {
    if (panels.isEmpty) return panels;

    final identifierSlots = <ProjectFormFieldSlot>[];
    final withoutIdentifier = <ProjectFormPanelLayout>[];

    for (final panel in panels) {
      final kept = <ProjectFormFieldSlot>[];
      for (final slot in panel.slots) {
        if (slot.field.isIdentifierField) {
          identifierSlots.add(slot);
        } else {
          kept.add(slot);
        }
      }
      if (kept.isEmpty) continue;
      withoutIdentifier.add(
        ProjectFormPanelLayout(
          nameKey: panel.nameKey,
          displayTitle: panel.displayTitle,
          slots: kept,
          isSystemPanel: panel.isSystemPanel,
        ),
      );
    }

    if (identifierSlots.isEmpty && withoutIdentifier.isEmpty) {
      return panels;
    }

    final generalIndex = withoutIdentifier.indexWhere(_isGeneralPanel);
    ProjectFormPanelLayout generalPanel;
    final others = <ProjectFormPanelLayout>[];

    if (generalIndex >= 0) {
      final existing = withoutIdentifier[generalIndex];
      generalPanel = ProjectFormPanelLayout(
        nameKey: existing.nameKey,
        displayTitle: existing.displayTitle,
        slots: [...identifierSlots, ...existing.slots],
        isSystemPanel: existing.isSystemPanel,
      );
      for (var i = 0; i < withoutIdentifier.length; i++) {
        if (i != generalIndex) others.add(withoutIdentifier[i]);
      }
    } else if (identifierSlots.isEmpty) {
      // Pas d’identifiant : remonter quand même le panneau Général s’il existe.
      final idx = panels.indexWhere(_isGeneralPanel);
      if (idx <= 0) return panels;
      return [
        panels[idx],
        ...panels.where((p) => !identical(p, panels[idx])),
      ];
    } else {
      generalPanel = ProjectFormPanelLayout(
        nameKey: 'common.header.general',
        displayTitle: 'Général',
        slots: identifierSlots,
      );
      others.addAll(withoutIdentifier);
    }

    return [generalPanel, ...others];
  }

  static bool _isGeneralPanel(ProjectFormPanelLayout panel) {
    final key = panel.nameKey.trim().toLowerCase();
    if (key == 'common.header.general' ||
        key == 'general' ||
        key == 'général' ||
        key.endsWith('.general') ||
        key.endsWith('.général')) {
      return true;
    }
    final title = panel.displayTitle.trim().toLowerCase();
    return title == 'général' || title == 'general';
  }

  static ProjectFormFieldSlot? _slotFromColumn(
    dynamic colRaw,
    Map<int, ProjectFormField> fieldsById,
  ) {
    if (colRaw is! Map) return null;
    final col = Map<String, dynamic>.from(colRaw);
    final fieldIdRaw = col['fieldId'];
    int? fieldId;
    if (fieldIdRaw is int) {
      fieldId = fieldIdRaw;
    } else if (fieldIdRaw is num) {
      fieldId = fieldIdRaw.toInt();
    }
    if (fieldId == null) return null;

    final field = fieldsById[fieldId];
    if (field == null) return null;

    final layoutRequired = col['isRequired'] == true;
    return ProjectFormFieldSlot(
      field: field,
      isRequired: layoutRequired || field.isRequired,
      isReadOnly: col['isReadOnly'] == true,
    );
  }

  static List<ProjectFormPanelLayout> _singlePanelFallback(
    Map<int, ProjectFormField> fieldsById,
  ) {
    final sorted = fieldsById.values.toList()
      ..sort((a, b) => a.fieldId.compareTo(b.fieldId));
    return [
      ProjectFormPanelLayout(
        nameKey: 'common.header.general',
        displayTitle: 'Général',
        slots: sorted
            .map(
              (f) => ProjectFormFieldSlot(
                field: f,
                isRequired: f.isRequired,
                isReadOnly: false,
              ),
            )
            .toList(),
      ),
    ];
  }

  /// Libellé affichable pour une clé de panneau (`name` du layout).
  static String panelTitleFromKey(String nameKey) {
    const known = <String, String>{
      'common.header.general': 'Général',
      'common.label.localisation': 'Localisation',
      'common.label.selectedSpatialUnits': 'Lieux',
      'common.label.spatialContext': 'Contexte spatial',
    };
    final trimmed = nameKey.trim();
    if (known.containsKey(trimmed)) return known[trimmed]!;

    final segment = trimmed.contains('.')
        ? trimmed.split('.').last
        : trimmed;
    if (segment.isEmpty) return trimmed;

    final words = segment
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map(_capitalizeWord)
        .toList();
    return words.join(' ');
  }

  static String _capitalizeWord(String w) {
    if (w.isEmpty) return w;
    return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
  }
}
