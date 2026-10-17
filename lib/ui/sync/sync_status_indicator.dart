import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/sync_service.dart';
import '../settings/supabase_settings_dialog.dart';
import 'sync_state_glyph.dart';
import 'sync_status_label.dart';

/// Sync status next to the cloud settings button: an icon for the sync run state, with a tooltip
/// (hover on desktop, long press on mobile) that names the state and the last completed sync.
/// Tapping it opens the cloud settings. Hidden without a connected user.
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // The countdown of a retry wait is redrawn each second; no timer runs in the other states.
  void _updateTicker(bool waiting) {
    if (waiting && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (!waiting) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    if (!sync.isAuthenticated) {
      _updateTicker(false);
      return const SizedBox.shrink();
    }

    final state = sync.runState;
    final dueAt = sync.retryDueAt;
    final setAside = sync.setAsideCount > 0;
    _updateTicker(state == SyncRunState.waitingToRetry && dueAt != null);

    final text = syncStatusText(
      state,
      failure: sync.lastFailure,
      retryInSeconds: dueAt == null ? 0 : syncRetryCountdown(dueAt),
      setAside: setAside,
    );

    return Semantics(
      button: true,
      label: text,
      child: Tooltip(
        message: '$text\n${syncLastSyncedLabel(sync.lastSyncedAt)}',
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 24,
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const SupabaseSettingsDialog(),
            );
          },
          child: SyncStateGlyph(state: state, color: widget.color, size: widget.size, setAside: setAside),
        ),
      ),
    );
  }
}
