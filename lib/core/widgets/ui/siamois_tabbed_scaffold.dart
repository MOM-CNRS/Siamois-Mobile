import 'package:flutter/material.dart';

import '../../theme/siamois_colors.dart';
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
    final hasDrawer =
        widget.showNavigationDrawer && widget.onLogout != null;
    final canPop = Navigator.canPop(context);
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SiamoisColors.surface,
      drawer: hasDrawer
          ? SiamoisNavigationDrawer(
              headerTitle: widget.drawerHeaderTitle ?? widget.title,
              headerSubtitle:
                  widget.drawerHeaderSubtitle ?? widget.subtitle,
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
                    onPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
        title: Column(
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
        actions: [
          const SiamoisAppBarSyncStrip(compact: true),
          ...widget.actions,
        ],
        bottom: showTabs
            ? TabBar(
                controller: widget.tabController,
                tabs: widget.tabs,
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
