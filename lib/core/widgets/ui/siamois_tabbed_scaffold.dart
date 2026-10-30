import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
import '../../theme/siamois_entity_style.dart';
import '../siamois_navigation_drawer.dart';
import '../sync/siamois_app_bar_sync_strip.dart';
import 'siamois_error_state.dart';
import 'siamois_spacing.dart';

/// Scaffold standard pour les écrans à onglets (projet, UE…).
class SiamoisTabbedScaffold extends StatefulWidget {
  const SiamoisTabbedScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.tabController,
    required this.tabs,
    required this.children,
    this.loading = false,
    this.errorMessage,
    this.onRetry,
    this.onLogout,
    this.drawerHeaderTitle,
    this.drawerHeaderSubtitle,
    this.showNavigationDrawer = true,
    this.floatingActionButton,
    this.entityKind,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final TabController tabController;
  final List<Widget> tabs;
  final List<Widget> children;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Future<void> Function()? onLogout;
  final String? drawerHeaderTitle;
  final String? drawerHeaderSubtitle;
  final bool showNavigationDrawer;
  final Widget? floatingActionButton;

  /// Entité de l'écran : icône colorée devant le titre, onglets et sections
  /// à sa couleur.
  final SiamoisEntityKind? entityKind;

  @override
  State<SiamoisTabbedScaffold> createState() => _SiamoisTabbedScaffoldState();
}

class _SiamoisTabbedScaffoldState extends State<SiamoisTabbedScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorMessage != null;
    final showTabs = !widget.loading && !hasError;
    final hasDrawer = widget.showNavigationDrawer && widget.onLogout != null;
    final canPop = Navigator.canPop(context);
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    final kind = widget.entityKind;

    final scaffold = Scaffold(
      key: _scaffoldKey,
      backgroundColor: SiamoisColors.surface,
      drawer: hasDrawer
          ? SiamoisNavigationDrawer(
              headerTitle: widget.drawerHeaderTitle ?? widget.title,
              headerSubtitle: widget.drawerHeaderSubtitle ?? widget.subtitle,
              onLogout: widget.onLogout!,
            )
          : null,
      appBar: AppBar(
        toolbarHeight: hasSubtitle ? 68 : kToolbarHeight,
        automaticallyImplyLeading: false,
        leading: canPop
            ? BackButton(
                onPressed: () => Navigator.of(context).pop(),
              )
            : hasDrawer
                ? SiamoisMenuButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
        title: _TitleWithIcon(
          kind: kind,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
              if (hasSubtitle)
                Text(
                  widget.subtitle!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SiamoisColors.textSecondary,
                    height: 1.2,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          const SiamoisAppBarSyncStrip(compact: true),
          ...widget.actions,
        ],
        bottom: showTabs
            ? TabBar(
                controller: widget.tabController,
                tabs: widget.tabs,
                // Comme les fiches web : onglet actif en vert Siamois neutre,
                // quelle que soit l'entité.
                labelColor: SiamoisColors.green,
                indicator: UnderlineTabIndicator(
                  borderSide:
                      const BorderSide(color: SiamoisColors.green, width: 2.5),
                  borderRadius: BorderRadius.circular(2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              )
            : null,
      ),
      body: widget.loading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? SiamoisErrorState(
                  message: widget.errorMessage!,
                  onRetry: widget.onRetry ?? () {},
                )
              : TabBarView(
                  controller: widget.tabController,
                  children: widget.children,
                ),
      floatingActionButton: widget.floatingActionButton,
    );
    return kind == null
        ? scaffold
        : SiamoisEntityScope(kind: kind, child: scaffold);
  }
}

class _TitleWithIcon extends StatelessWidget {
  const _TitleWithIcon({required this.kind, required this.child});

  final SiamoisEntityKind? kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kind = this.kind;
    if (kind == null) return child;
    return Row(
      children: [
        Icon(kind.icon, size: 22, color: kind.color),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

/// Padding standard pour le contenu des onglets détail.
class SiamoisDetailTabPadding extends StatelessWidget {
  const SiamoisDetailTabPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.md,
        SiamoisSpacing.pageHorizontal,
        SiamoisSpacing.xxl,
      ),
      child: child,
    );
  }
}

/// Onglet d'une liste d'entités, comme sur le web : icône de l'entité,
/// libellé et compteur dans une pastille grise.
class SiamoisEntityCountTab extends StatelessWidget {
  const SiamoisEntityCountTab({
    super.key,
    required this.kind,
    required this.label,
    required this.count,
  });

  final SiamoisEntityKind kind;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 18, color: kind.color),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: SiamoisColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: SiamoisColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
