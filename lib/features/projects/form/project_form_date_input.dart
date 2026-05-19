import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'project_form_models.dart';

/// Sélecteur de date en français (calendrier Material localisé).
class ProjectFormDateInput extends StatelessWidget {
  const ProjectFormDateInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final ProjectFormField field;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  static final _displayFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  static final _shortFormat = DateFormat('dd/MM/yyyy', 'fr_FR');

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: value ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 30),
      helpText: 'Choisir une date',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      fieldLabelText: field.label,
      errorFormatText: 'Format invalide',
      errorInvalidText: 'Date invalide',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  String _formatDisplay(DateTime date) {
    try {
      return _displayFormat.format(date);
    } catch (_) {
      return _shortFormat.format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = value == null ? 'Choisir une date' : _formatDisplay(value!);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.hint,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_month_rounded),
      ),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        value != null ? FontWeight.w500 : FontWeight.normal,
                    color: value != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (value != null)
                IconButton(
                  tooltip: 'Effacer la date',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
