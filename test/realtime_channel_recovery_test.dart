import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a SUBSCRIBED after an interruption is a reconnection; the first SUBSCRIBED of a channel is not', () {
    final connection = RealtimeConnection();
    expect(connection.onStatus(RealtimeSubscribeStatus.subscribed), isFalse);
    expect(connection.onStatus(RealtimeSubscribeStatus.channelError), isFalse);
    expect(connection.onStatus(RealtimeSubscribeStatus.timedOut), isFalse);
    expect(connection.onStatus(RealtimeSubscribeStatus.closed), isFalse);
    expect(connection.onStatus(RealtimeSubscribeStatus.subscribed), isTrue, reason: 'REALTIME_CONNECTED');
    expect(connection.onStatus(RealtimeSubscribeStatus.subscribed), isFalse, reason: 'already listening');
  });

  test('changes are applied one at a time in arrival order, and a failed one does not stop the next', () async {
    final gate = Completer<void>();
    final applied = <String>[];
    final failures = <Object>[];
    final queue = RealtimeChangeQueue(failures.add);

    queue.add(() async {
      await gate.future;
      applied.add('first');
    });
    queue.add(() async {
      applied.add('second');
      throw StateError('not applied');
    });
    final last = queue.add(() async => applied.add('third'));

    await Future<void>.delayed(Duration.zero);
    expect(applied, isEmpty, reason: 'the first change is still running');
    gate.complete();
    await last;

    expect(applied, ['first', 'second', 'third']);
    expect(failures, hasLength(1));
    expect(failures.single, isA<StateError>());
  });

  test('clearing the queue discards the changes not yet applied, so a closed channel applies nothing', () async {
    final gate = Completer<void>();
    final applied = <String>[];
    final queue = RealtimeChangeQueue((_) {});

    final running = queue.add(() async {
      await gate.future;
      applied.add('running');
    });
    queue.add(() async => applied.add('pending'));

    await Future<void>.delayed(Duration.zero);
    queue.clear();
    gate.complete();
    await running;
    await queue.add(() async => applied.add('after clear'));

    expect(applied, ['running', 'after clear'], reason: 'the change already running finishes; the pending one is dropped');
  });
}
