import 'package:flutter/material.dart';

import '../../features/auth/auth_models.dart';
import '../theme/siamois_colors.dart';
import 'siamois_navigation_drawer.dart';
import 'sync/siamois_app_bar_sync_strip.dart';
import 'ui/siamois_offline_banner.dart';
import 'ui/siamois_spacing.dart';

/// Barre de titre commune à l'application (titre, sous-titre, actions).
class SiamoisTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const SiamoisTitleBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.showBrandMark = true,
    this.showSyncChrome = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final bool showBrandMark;
  final bool showSyncChrome;

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  @override
  Size get preferredSize => Size.fromHeight(_hasSubtitle ? 80 : kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: SiamoisColors.surfaceCard,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SiamoisColors.borderSubtle),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SiamoisSpacing.md,
              10,
              4,
              12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 4),
                ],
                if (showBrandMark) ...[
                  const SiamoisLayersMark(size: 42),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      if (_hasSubtitle) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: SiamoisColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showSyncChrome) const SiamoisAppBarSyncStrip(compact: true),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chemin du logo officiel (barre de titre, splash, synchronisation).
abstract final class SiamoisAssets {
  static const logo = 'assets/images/siamois_logo.png';
}

/// Logo officiel Siamois — image PNG dans un conteneur arrondi.
///
/// Sur fond clair (app bar) : conteneur blanc avec ombre légère.
/// Sur fond sombre (hero login) : utiliser [SiamoisLayersMark] directement.
class SiamoisLayersMark extends StatelessWidget {
  const SiamoisLayersMark({super.key, this.size = 42, this.onDark = false});

  final double size;

  /// true = fond sombre (hero) → conteneur blanc pour que le logo reste lisible.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    final bg = onDark ? Colors.white : SiamoisColors.surfaceCard;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: onDark ? 0.22 : 0.12),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.07),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Image.asset(
            SiamoisAssets.logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// [Scaffold] avec [SiamoisTitleBar] intégrée et menu latéral optionnel.
class SiamoisScaffold extends StatefulWidget {
  const SiamoisScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBrandMark = true,
    this.toolbar,
    this.offlineBannerDetail,
    this.onLogout,
    this.drawerHeaderTitle,
    this.drawerHeaderSubtitle,
    this.organizations = const [],
    this.selectedOrganizationId,
    this.onOrganizationSelected,
    this.organizationsEnabled = true,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBrandMark;
  final Widget? toolbar;
  final String? offlineBannerDetail;
  final Future<void> Function()? onLogout;
  final String? drawerHeaderTitle;
  final String? drawerHeaderSubtitle;
  final List<StoredOrganization> organizations;
  final int? selectedOrganizationId;
  final ValueChanged<StoredOrganization>? onOrganizationSelected;
  final bool organizationsEnabled;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  State<SiamoisScaffold> createState() => _SiamoisScaffoldState();
}

class _SiamoisScaffoldState extends State<SiamoisScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final hasDrawer = widget.onLogout != null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: SiamoisColors.surface,
      drawer: hasDrawer
          ? SiamoisNavigationDrawer(
              headerTitle: widget.drawerHeaderTitle ?? widget.title,
              headerSubtitle:
                  widget.drawerHeaderSubtitle ?? widget.subtitle,
              onLogout: widget.onLogout!,
              organizations: widget.organizations,
              selectedOrganizationId: widget.selectedOrganizationId,
              onOrganizationSelected: widget.onOrganizationSelected,
              organizationsEnabled: widget.organizationsEnabled,
            )
          : null,
      appBar: SiamoisTitleBar(
        title: widget.title,
        subtitle: widget.subtitle,
        leading: hasDrawer
            ? SiamoisMenuButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : null,
        actions: widget.actions,
        showBrandMark: widget.showBrandMark,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.toolbar != null) widget.toolbar!,
          SiamoisOfflineBanner(detail: widget.offlineBannerDetail),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
