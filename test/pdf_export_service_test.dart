import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/pdf_export_service.dart';

void main() {
  test('a second export request is ignored while the print dialog is open', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('it_IT');
    const channel = MethodChannel('net.nfet.printing');
    var printDialogs = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        if (call.method == 'printPdf') printDialogs++;
        return null;
      },
    );
    final note = Note(
      id: 'n1',
      title: 'Nota',
      content: '[]',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
    );

    // The first dialog stays open (its future never completes in this test).
    unawaited(PdfExportService.exportNoteToPdf(note, confirmPin: () async => true));
    await Future<void>.delayed(Duration.zero);
    await PdfExportService.exportNoteToPdf(note, confirmPin: () async => true);
    await Future<void>.delayed(Duration.zero);

    expect(printDialogs, 1);
  });

  test('an empty checklist, bullet or heading line keeps its marker', () {
    expect(hasMarker('- [ ]', '- [ ] '), isTrue);
    expect(afterMarker('- [ ]', '- [ ] '), '');
    expect(hasMarker('-', '- '), isTrue);
    expect(afterMarker('-', '- '), '');
    expect(hasMarker('#', '# '), isTrue);
    expect(afterMarker('#', '# '), '');
    expect(hasMarker('- [x] Fatto', '- [x] '), isTrue);
    expect(afterMarker('- [x] Fatto', '- [x] '), 'Fatto');
    expect(hasMarker('#tag', '# '), isFalse);
  });

  test('an empty heading keeps a non-breaking space so it takes line height', () {
    expect(headingText('#', '# '), '\u00A0');
    expect(headingText('## ', '## '), '\u00A0');
    expect(headingText('### Sezione', '### '), 'Sezione');
  });

  test('the PDF embeds Unicode fonts instead of the Latin-1 Helvetica', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('it_IT');
    final note = Note(
      id: 'n2',
      title: 'Prezzo € “citazione” — Привет 😀',
      content: '[]',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
    );

    final pdf = String.fromCharCodes(await PdfExportService.buildPdfBytes(note));

    expect(pdf, contains('DejaVuSans'));
    expect(pdf, isNot(contains('Helvetica')));
  });

  test('an indented heading line is built as a heading, not a paragraph', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('it_IT');
    final note = Note(
      id: 'n3',
      title: 'Titolo',
      content: 'Titolo\n  # Sezione rientrata\ncorpo',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 2),
    );

    expect(note.toMarkdownBody(), contains('  # Sezione rientrata'));
    expect(await PdfExportService.buildPdfBytes(note), isNotEmpty);
  });
}
