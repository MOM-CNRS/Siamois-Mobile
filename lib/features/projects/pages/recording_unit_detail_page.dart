import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart' hide Form;
import '../../../core/routes.dart';
import '../../../core/widgets/ui/siamois_tabbed_scaffold.dart';
import '../../auth/auth_repository.dart';
import '../documents/recording_unit_document_store.dart';
import '../mobiliers/mobilier_list_store.dart';
import '../project_detail_models.dart';
import '../recording_units/recording_unit_detail_mapper.dart';
import '../recording_units/recording_unit_detail_models.dart';
import '../recording_units/recording_unit_detail_store.dart';
import 'recording_unit_form_page.dart';
import 'recording_unit_detail_detail_tab.dart';
import 'recording_unit_detail_documents_tab.dart';
import 'recording_unit_detail_mobiliers_tab.dart';

/// Détail d'une unité d'enregistrement avec onglets Détail / Documents / Mobiliers.
class RecordingUnitDetailPage extends StatefulWidget {
  const RecordingUnitDetailPage({
    super.key,
    required this.auth,
    required this.database,
    required this.recordingUnitId,
    this.projectId,
    this.summary,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final String recordingUnitId;
  final String? projectId;
  final RecordingUnitItem? summary;

  @override
  State<RecordingUnitDetailPage> createState() =>
      _RecordingUnitDetailPageState();
}

class _RecordingUnitDetailPageState extends State<RecordingUnitDetailPage>
    with SingleTickerProviderStateMixin {
  RecordingUnitMobileDetail? _detail;
  String? _loadError;
  bool _loading = true;
  int _documentCount = 0;
  int _mobilierCount = 0;

  late final TabController _tabController;
  late final RecordingUnitDocumentStore _documentStore;
  late final RecordingUnitDetailStore _detailStore;
  late final MobilierListStore _mobilierStore;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _documentStore = RecordingUnitDocumentStore(
      auth: widget.auth,
      db: widget.database,
    );
    _detailStore = RecordingUnitDetailStore(
      auth: widget.auth,
      db: widget.database,
    );
    _mobilierStore = MobilierListStore(
      auth: widget.auth,
      db: widget.database,
    );
    _tabController.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await _detailStore.load(
        widget.recordingUnitId,
        summary: widget.summary,
      );
      final counts = await _fetchTabCounts();
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _documentCount = counts.$1;
        _mobilierCount = counts.$2;
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
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

  Future<(int, int)> _fetchTabCounts() async {
    // En ligne : charge l’API et met à jour le cache SQLite des documents UE.
    final docs = await _documentStore.loadForRecordingUnit(
      widget.recordingUnitId,
    );
    final mobiliers = await _mobilierStore.loadPage(
      recordingUnitId: widget.recordingUnitId,
      offset: 0,
      limit: 1,
    );
    return (docs.length, mobiliers.total);
  }

  Future<void> _logout() async {
    await widget.auth.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  Future<void> _openEdit() async {
    final detail = _detail;
    if (detail == null) return;

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => RecordingUnitFormPage(
          auth: widget.auth,
          database: widget.database,
          recordingUnitId: widget.recordingUnitId,
          initialDetail: detail,
          projectId: widget.projectId,
        ),
      ),
    );

    if (!mounted) return;
    if (result == 'deleted') {
      Navigator.of(context).pop('deleted');
      return;
    }
    if (result is RecordingUnitMobileDetail) {
      await _load();
    }
  }

  Future<void> _refreshTabCounts() async {
    try {
      final counts = await _fetchTabCounts();
      if (!mounted) return;
      setState(() {
        _documentCount = counts.$1;
        _mobilierCount = counts.$2;
      });
    } catch (_) {
      // Les onglets affichent déjà leur propre état ; ignorer en silence.
    }
  }

  String _tabLabel(String base, int count) => '$base ($count)';

  String get _title {
    final summary = widget.summary;
    if (summary != null && summary.displayCode.trim().isNotEmpty) {
      return summary.displayCode;
    }
    final detail = _detail;
    if (detail != null && detail.displayCode.trim().isNotEmpty) {
      return detail.displayCode;
    }
    return 'Unité d’enregistrement';
  }

  String? get _subtitle {
    final summary = widget.summary;
    final fromSummary = [
      summary?.typeLabel,
      summary?.placeLabel,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    if (fromSummary.isNotEmpty) return fromSummary;

    final detail = _detail;
    if (detail != null) {
      final sub = RecordingUnitDetailMapper.headerSubtitle(detail);
      if (sub != null && sub.trim().isNotEmpty) return sub;
    }
    return null;
  }

  List<Widget> _buildTabChildren() {
    final detail = _detail;
    if (detail == null) {
      return const [
        SizedBox.shrink(),
        SizedBox.shrink(),
        SizedBox.shrink(),
      ];
    }
    return [
      RecordingUnitDetailDetailTab(
        detail: detail,
        auth: widget.auth,
        database: widget.database,
        recordingUnitId: widget.recordingUnitId,
      ),
      RecordingUnitDetailDocumentsTab(
        auth: widget.auth,
        database: widget.database,
        recordingUnitId: widget.recordingUnitId,
        onListChanged: _refreshTabCounts,
      ),
      RecordingUnitDetailMobiliersTab(
        auth: widget.auth,
        database: widget.database,
        recordingUnitId: widget.recordingUnitId,
        onListChanged: _refreshTabCounts,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.auth.userProfile;
    final canEdit = !_loading && _loadError == null && _detail != null;

    return SiamoisTabbedScaffold(
      title: _title,
      subtitle: _subtitle,
      loading: _loading,
      errorMessage: _loadError,
      onRetry: _load,
      onLogout: _logout,
      drawerHeaderSubtitle: profile?.organizationLine,
      floatingActionButton: canEdit && _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            )
          : null,
      tabController: _tabController,
      tabs: [
        const Tab(text: 'Détail'),
        Tab(text: _tabLabel('Documents', _documentCount)),
        Tab(text: _tabLabel('Mobiliers', _mobilierCount)),
      ],
      children: _buildTabChildren(),
    );
  }
}
