import 'package:flutter/material.dart';

import '../../../core/widgets/ui/siamois_messenger.dart';
import '../../../core/widgets/ui/siamois_select_field.dart';
import '../../../core/widgets/ui/siamois_spacing.dart';
import '../../auth/auth_repository.dart';
import 'spatial_unit_store.dart';
import '../vocabulary_models.dart';
import 'spatial_unit_local_id.dart';
import 'spatial_unit_models.dart';

/// Formulaire de création d'un lieu (Nom, Catégorie, Adresse).
Future<PlaceListItem?> showSpatialUnitCreateSheet({
  required BuildContext context,
  required SpatialUnitStore store,
  required AuthRepository auth,
  required int organizationId,
  List<ConceptOption> initialCategories = const [],
}) {
  return _showSpatialUnitFormSheet(
    context: context,
    store: store,
    auth: auth,
    organizationId: organizationId,
    initialCategories: initialCategories,
  );
}

/// Formulaire de modification d'un lieu existant.
Future<PlaceListItem?> showSpatialUnitEditSheet({
  required BuildContext context,
  required SpatialUnitStore store,
  required AuthRepository auth,
  required int organizationId,
  required PlaceListItem item,
  List<ConceptOption> initialCategories = const [],
}) {
  return _showSpatialUnitFormSheet(
    context: context,
    store: store,
    auth: auth,
    organizationId: organizationId,
    initialCategories: initialCategories,
    editItem: item,
  );
}

Future<PlaceListItem?> _showSpatialUnitFormSheet({
  required BuildContext context,
  required SpatialUnitStore store,
  required AuthRepository auth,
  required int organizationId,
  List<ConceptOption> initialCategories = const [],
  PlaceListItem? editItem,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<PlaceListItem>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    builder: (ctx) => _SpatialUnitCreateSheet(
      store: store,
      auth: auth,
      organizationId: organizationId,
      initialCategories: initialCategories,
      editItem: editItem,
    ),
  );
}

class _SpatialUnitCreateSheet extends StatefulWidget {
  const _SpatialUnitCreateSheet({
    required this.store,
    required this.auth,
    required this.organizationId,
    required this.initialCategories,
    this.editItem,
  });

  final SpatialUnitStore store;
  final AuthRepository auth;
  final int organizationId;
  final List<ConceptOption> initialCategories;
  final PlaceListItem? editItem;

  @override
  State<_SpatialUnitCreateSheet> createState() => _SpatialUnitCreateSheetState();
}

class _SpatialUnitCreateSheetState extends State<_SpatialUnitCreateSheet> {
  final _nameController = TextEditingController();
  final _categoryQueryController = TextEditingController();
  final _addressController = TextEditingController();

  List<ConceptOption> _allCategories = const [];
  List<ConceptOption> _categorySuggestions = const [];
  List<FullAddressOption> _addressSuggestions = const [];
  ConceptOption? _selectedCategory;
  FullAddressOption? _selectedAddress;
  bool _loadingCategories = false;
  bool _loadingAddresses = false;
  bool _preparingEdit = false;
  bool _submitting = false;

  bool get _isEditing => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    _allCategories = List<ConceptOption>.from(widget.initialCategories);
    _categorySuggestions = _allCategories;
    _prepareForm();
  }

  Future<void> _prepareForm() async {
    if (_isEditing) {
      _applyItemPrefill(widget.editItem!);
      if (mounted) setState(() => _preparingEdit = true);
    }

    await _refreshCategoriesFromApi();

    if (_isEditing && mounted) {
      await _applyDetailPrefill(widget.editItem!);
      setState(() => _preparingEdit = false);
    }
  }

  void _applyItemPrefill(PlaceListItem item) {
    _nameController.text = item.place.label;
    if (item.address != null) {
      _selectedAddress = item.address;
      _addressController.text = item.address!.label;
    }
    final typeId = item.typeConceptId;
    if (typeId != null) {
      _selectedCategory = _categoryOptionFor(typeId);
      _categoryQueryController.text = _selectedCategory!.label;
    }
  }

  Future<void> _applyDetailPrefill(PlaceListItem item) async {
    final detail = await widget.store.loadDetailForEdit(
      organizationId: widget.organizationId,
      placeId: item.place.id,
    );
    if (!mounted) return;

    if (detail != null) {
      _nameController.text = detail.name;
      if (detail.address != null) {
        _selectedAddress = detail.address;
        _addressController.text = detail.address!.label;
      }
      final typeId = detail.typeConceptId ?? item.typeConceptId;
      if (typeId != null) {
        _selectedCategory = _categoryOptionFor(typeId);
        _categoryQueryController.text = _selectedCategory!.label;
      }
    } else if (item.typeConceptId != null) {
      _selectedCategory = _categoryOptionFor(item.typeConceptId!);
      _categoryQueryController.text = _selectedCategory!.label;
    }

    setState(() {});
  }

  ConceptOption _categoryOptionFor(int typeConceptId) {
    for (final category in _allCategories) {
      if (category.id == typeConceptId) return category;
    }
    return ConceptOption(
      id: typeConceptId,
      label: 'Catégorie $typeConceptId',
    );
  }

  Future<void> _refreshCategoriesFromApi() async {
    setState(() => _loadingCategories = true);
    try {
      final fromApi = await widget.auth.fetchVocabulariesByFieldCode(
        organizationId: widget.organizationId,
      );
      final categories =
          ConceptOption.spatialUnitCategoriesFromVocabularies(fromApi);
      if (!mounted) return;
      setState(() {
        _allCategories = categories;
        _categorySuggestions = categories;
        if (_selectedCategory != null) {
          _selectedCategory = _categoryOptionFor(_selectedCategory!.id);
          _categoryQueryController.text = _selectedCategory!.label;
        }
      });
    } on AuthException {
      // Les catégories initiales / cache restent affichées.
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryQueryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchCategories(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _categorySuggestions = _allCategories);
      return;
    }

    final local = _allCategories
        .where((c) => c.label.toLowerCase().contains(q.toLowerCase()))
        .toList();
    if (local.isNotEmpty) {
      setState(() => _categorySuggestions = local);
      return;
    }

    setState(() => _loadingCategories = true);
    try {
      final remote = await widget.auth.searchConceptAutocomplete(
        organizationId: widget.organizationId,
        fieldCode: 'SIASU.TYPE',
        query: q,
      );
      if (!mounted) return;
      setState(() {
        _categorySuggestions = remote.isNotEmpty ? remote : local;
      });
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _searchAddresses(String query) async {
    final q = query.trim();
    if (q.length < 3) {
      setState(() => _addressSuggestions = const []);
      return;
    }

    setState(() => _loadingAddresses = true);
    try {
      final results = await widget.auth.searchAddressSuggestions(q);
      if (mounted) setState(() => _addressSuggestions = results);
    } finally {
      if (mounted) setState(() => _loadingAddresses = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showErrorMessage('Le nom est obligatoire.');
      return;
    }
    final category = _selectedCategory;
    if (category == null) {
      context.showErrorMessage('La catégorie est obligatoire.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = CreateSpatialUnitRequest(
        organizationId: widget.organizationId,
        name: name,
        typeConceptId: category.id,
        address: _selectedAddress,
      );
      final result = _isEditing
          ? await widget.store.updateItem(
              placeId: widget.editItem!.place.id,
              request: request,
            )
          : await widget.store.createItem(request);
      if (!mounted) return;
      final pending = result.pendingSync ||
          SpatialUnitLocalId.isLocalId(result.place.id);
      if (pending) {
        context.showInfoMessage(
          'Lieu enregistré localement. Il sera synchronisé dès que la connexion '
          'sera rétablie.',
        );
      }
      Navigator.of(context).pop(result);
    } on AuthException catch (e) {
      if (mounted) context.showErrorMessage(e.message);
    } catch (e) {
      if (mounted) context.showErrorMessage('Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildCategoryField(ThemeData theme) {
    if (_selectedCategory != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: SiamoisFieldDecoration.forField(label: 'Catégorie'),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(_selectedCategory!.label),
                onDeleted: _preparingEdit
                    ? null
                    : () => setState(() {
                          _selectedCategory = null;
                          _categoryQueryController.clear();
                          _categorySuggestions = _allCategories;
                        }),
              ),
            ),
          ),
        ],
      );
    }

    if (_allCategories.isNotEmpty) {
      return InputDecorator(
        decoration: SiamoisFieldDecoration.forField(
          label: 'Catégorie',
          hint: 'Choisir…',
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: null,
            hint: const Text('Choisir…'),
            items: _allCategories
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
            onChanged: _preparingEdit
                ? null
                : (id) {
                    if (id == null) return;
                    final match = _categoryOptionFor(id);
                    setState(() {
                      _selectedCategory = match;
                      _categoryQueryController.text = match.label;
                    });
                  },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _categoryQueryController,
          decoration: SiamoisFieldDecoration.forField(
            label: 'Catégorie',
            hint: 'Rechercher dans OpenTheso…',
            suffixIcon: _loadingCategories
                ? SiamoisFieldDecoration.loadingSuffix()
                : SiamoisFieldDecoration.searchSuffix(),
          ),
          onChanged: _searchCategories,
        ),
        if (_allCategories.isEmpty && !_loadingCategories)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Aucune catégorie chargée. Configurez le thésaurus OpenTheso '
              '(field code SIASU.TYPE) ou saisissez un terme pour rechercher.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (_categorySuggestions.isNotEmpty)
          SiamoisSelectSuggestionsPanel(
            header: 'Catégories',
            children: _categorySuggestions
                .map(
                  (item) => SiamoisSelectSuggestionTile(
                    title: item.label,
                    leading: const Icon(Icons.category_outlined, size: 20),
                    onTap: () {
                      setState(() {
                        _selectedCategory = item;
                        _categoryQueryController.text = item.label;
                        _categorySuggestions = const [];
                      });
                    },
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Modifier le lieu' : 'Nouveau lieu',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              _isEditing
                  ? 'Modifiez les informations du lieu.'
                  : 'Créez un lieu dans votre organisation, puis sélectionnez-le dans le formulaire.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: SiamoisSpacing.lg),
            TextField(
              controller: _nameController,
              decoration: SiamoisFieldDecoration.forField(label: 'Nom'),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: SiamoisSpacing.md),
            _buildCategoryField(theme),
            const SizedBox(height: SiamoisSpacing.md),
            TextField(
              controller: _addressController,
              decoration: SiamoisFieldDecoration.forField(
                label: 'Adresse',
                hint: 'Ex. : 7 rue de la paix Lyon',
                suffixIcon: _loadingAddresses
                    ? SiamoisFieldDecoration.loadingSuffix()
                    : SiamoisFieldDecoration.clearSuffix(
                        visible: _selectedAddress != null,
                        onClear: () {
                          setState(() {
                            _selectedAddress = null;
                            _addressController.clear();
                            _addressSuggestions = const [];
                          });
                        },
                      ) ??
                        SiamoisFieldDecoration.searchSuffix(),
              ),
              onChanged: _searchAddresses,
            ),
            SiamoisSelectSuggestionsPanel(
              header: _addressSuggestions.isNotEmpty ? 'Adresses' : null,
              children: _addressSuggestions
                  .map(
                    (item) => SiamoisSelectSuggestionTile(
                      title: item.label,
                      subtitle: [
                        if (item.postcode != null) item.postcode,
                        if (item.city != null) item.city,
                      ].whereType<String>().join(' '),
                      leading: const Icon(Icons.location_on_outlined, size: 20),
                      onTap: () {
                        setState(() {
                          _selectedAddress = item;
                          _addressController.text = item.label;
                          _addressSuggestions = const [];
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: SiamoisSpacing.lg),
            FilledButton(
              onPressed: _submitting || _preparingEdit ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Enregistrer' : 'Créer le lieu'),
            ),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
