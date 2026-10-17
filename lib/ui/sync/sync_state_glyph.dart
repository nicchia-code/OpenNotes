import 'package:flutter/cupertino.dart';

import '../../core/services/sync_service.dart';

/// Icon of a sync run state: a CupertinoIcons cloud with a small state badge over it
/// (checkmark, exclamation mark, slashed circle). While a run is going, a spinner.
/// Every part comes from the CupertinoIcons family, as the rest of the app.
class SyncStateGlyph extends StatelessWidget {
  const SyncStateGlyph({
    super.key,
    required this.state,
    required this.color,
    this.size = 16,
    this.setAside = false,
  });

  final SyncRunState state;
  final Color color;
  final double size;
  /// True while an idle run has changes set aside: the checkmark becomes an exclamation mark.
  final bool setAside;

  @override
  Widget build(BuildContext context) => switch (state) {
        SyncRunState.running => CupertinoActivityIndicator(radius: size / 2, color: color),
        SyncRunState.idle => _cloud(setAside ? CupertinoIcons.exclamationmark : CupertinoIcons.checkmark_alt),
        SyncRunState.waitingToRetry => _cloud(CupertinoIcons.exclamationmark),
        SyncRunState.offline => _cloud(CupertinoIcons.slash_circle_fill),
      };

  Widget _cloud(IconData badge) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(CupertinoIcons.cloud, size: size, color: color),
            Positioned(
              right: -size * 0.12,
              bottom: -size * 0.12,
              child: Icon(badge, size: size * 0.6, color: color),
            ),
          ],
        ),
      );
}
