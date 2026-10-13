import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/pdf_export_service.dart';

// Its own file: a print dialog that stays open keeps the service's static guard set.
void main() {
  test('a protected note opens the print dialog only after its PIN is confirmed', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('it_IT');
    const channel = MethodChannel('net.nfet.printing');
    var printDialogs = 0;
    final opened = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'printPdf') {
          printDialogs++;
          opened.complete();
        }
        return null;
      },
    );
    final note = Note(
      id: 'n3',
      title: 'Segreta',
      content: '[]',
      isLocked: true,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
    );

    var asked = 0;
    await PdfExportService.exportNoteToPdf(
      note,
      confirmPin: () async {
        asked++;
        return false;
      },
    );
    expect(asked, 1);
    expect(printDialogs, 0);

    unawaited(PdfExportService.exportNoteToPdf(note, confirmPin: () async => true));
    await opened.future;
    expect(printDialogs, 1);
  });
}
