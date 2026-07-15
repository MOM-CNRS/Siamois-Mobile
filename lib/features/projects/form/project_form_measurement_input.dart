import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/ui/siamois_select_field.dart';
import 'form_measurement_value.dart';
import 'project_form_models.dart';

/// Deux champs côte à côte : taille (réel, suffixe m) + commentaire.
class ProjectFormMeasurementInput extends StatelessWidget {
  const ProjectFormMeasurementInput({
    super.key,
    required this.field,
    required this.numericController,
    required this.commentController,
    this.isRequired = false,
  });

  final ProjectFormField field;
  final TextEditingController numericController;
  final TextEditingController commentController;
  final bool isRequired;

  static final _decimalInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*([.,])?\d*'),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (field.hint != null && field.hint!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              field.hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: numericController,
                decoration: InputDecoration(
                  labelText: SiamoisFieldDecoration.requiredLabel(
                    field.label,
                    isRequired: isRequired,
                  ),
                  border: const OutlineInputBorder(),
                  suffixText: field.unitSymbol.isNotEmpty
                      ? field.unitSymbol
                      : 'm',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [_decimalInputFormatter],
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (isRequired && trimmed.isEmpty) {
                    return 'Taille obligatoire';
                  }
                  if (trimmed.isNotEmpty &&
                      FormMeasurementValue.parseDouble(trimmed) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
