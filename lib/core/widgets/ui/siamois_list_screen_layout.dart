import 'package:flutter/material.dart';

import 'siamois_offline_banner.dart';

/// Ordre standard des écrans liste :
/// barre de recherche (optionnelle) → bandeau hors ligne → contenu.
class SiamoisListScreenLayout extends StatelessWidget {
  const SiamoisListScreenLayout({
    super.key,
    this.toolbar,
    required this.child,
    this.offlineDetail,
    this.showOfflineBanner = true,
  });

  final Widget? toolbar;
  final Widget child;
  final String? offlineDetail;
  final bool showOfflineBanner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (toolbar != null) toolbar!,
        if (showOfflineBanner)
          SiamoisOfflineBanner(detail: offlineDetail),
        Expanded(child: child),
      ],
    );
  }
}
