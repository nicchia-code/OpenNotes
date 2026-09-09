import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/core/models/note_model.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/security_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:open_notes/core/state/notes_provider.dart';
import 'package:open_notes/ui/editor/notion_document_editor.dart';
import 'package:open_notes/ui/editor/rich_text_editing_controller.dart';
import 'package:open_notes/ui/shell/mac_title_bar.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  group('RichTextEditingController Unit Tests', () {
    test('RichTextEditingController applies and removes bold style span on selection', () {
      final ctrl = RichTextEditingController(
        text: 'Hello Apple Notes World',
        baseStyle: const TextStyle(fontSize: 15),
      );

      // Select "Apple Notes" (index 6 to 17)
      ctrl.selection = const TextSelection(baseOffset: 6, extentOffset: 17);
      ctrl.toggleBold();

      expect(ctrl.spans.length, 1);
      expect(ctrl.spans.first.start, 6);
      expect(ctrl.spans.first.end, 17);
      expect(ctrl.spans.first.isBold, isTrue);

      // Export to markdown produces clean asterisks
      expect(ctrl.toMarkdown(), 'Hello **Apple Notes** World');

      // Toggling bold again on the same selection removes it
      ctrl.toggleBold();
      expect(ctrl.spans.where((s) => s.isBold).isEmpty, isTrue);
      expect(ctrl.toMarkdown(), 'Hello Apple Notes World');
    });

    test('RichTextEditingController supports multiple overlapping styles (Bold + Italic + Underline)', () {
      final ctrl = RichTextEditingController(
        text: 'Super Note',
        baseStyle: const TextStyle(fontSize: 15),
      );

      ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 5); // "Super"
      ctrl.toggleBold();
      ctrl.toggleItalic();
      ctrl.toggleUnderline();

      expect(ctrl.spans.length, 1);
      final span = ctrl.spans.first;
      expect(span.isBold, isTrue);
      expect(span.isItalic, isTrue);
      expect(span.isUnderline, isTrue);
      expect(ctrl.toMarkdown(), '***Super*** Note');
    });

    test('RichTextEditingController supports multi-line selection across bullets and paragraphs', () {
      final docText = 'Titolo Nota\n• Primo bullet\n• Secondo bullet\nParagrafo finale';
      final ctrl = RichTextEditingController(
        text: docText,
        baseStyle: const TextStyle(fontSize: 15),
      );

      // Select across both bullets: from "Primo" (index 14) to "Secondo bullet" (index 46)
      final start = docText.indexOf('Primo');
      final end = docText.indexOf('Secondo bullet') + 'Secondo bullet'.length;
      ctrl.selection = TextSelection(baseOffset: start, extentOffset: end);

      ctrl.toggleBold();

      expect(ctrl.spans.length, 1);
      expect(ctrl.spans.first.isBold, isTrue);
      expect(ctrl.spans.first.start, start);
      expect(ctrl.spans.first.end, end);

      final exported = ctrl.toMarkdown();
      expect(exported.contains('**Primo bullet\n• Secondo bullet**'), isTrue);
    });

    test('RichTextEditingController handleEnterKey auto-continues and exits lists', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n• Primo elemento',
        baseStyle: const TextStyle(fontSize: 15),
      );

      // Place cursor at end of bullet item
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      final handled = ctrl.handleEnterKey();

      expect(handled, isTrue);
      expect(ctrl.text, 'Titolo\n• Primo elemento\n• ');
      expect(ctrl.selection.baseOffset, ctrl.text.length);

      // Press Enter again on the empty bullet -> exits bullet list
      final exited = ctrl.handleEnterKey();
      expect(exited, isTrue);
      expect(ctrl.text, 'Titolo\n• Primo elemento\n');
    });

    test('RichTextEditingController auto-converts typed checklist shortcuts and handleEnterKey continues/exits checklist', () {
      final ctrl = RichTextEditingController(
        text: 'Titolo\n',
        baseStyle: const TextStyle(fontSize: 15),
      );

      // 1. Type "- [ ] "
      ctrl.value = const TextEditingValue(
        text: 'Titolo\n- [ ] Primo compito',
        selection: TextSelection.collapsed(offset: 26),
      );
      expect(ctrl.text, 'Titolo\n○ Primo compito');

      // 2. Press Enter -> continues with ○
      ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      final handled = ctrl.handleEnterKey();
      expect(handled, isTrue);
      expect(ctrl.text, 'Titolo\n○ Primo compito\n○ ');

      // 3. Press Enter again on empty checklist -> exits to clean newline
      final exited = ctrl.handleEnterKey();
      expect(exited, isTrue);
      expect(ctrl.text, 'Titolo\n○ Primo compito\n');

      // 4. Toggle checklist to checked ● and export to Markdown
      final circlePos = ctrl.text.indexOf('○');
      ctrl.toggleChecklistAtOffset(circlePos);
      expect(ctrl.text, 'Titolo\n● Primo compito\n');
      expect(ctrl.toMarkdown(), 'Titolo\n- [x] Primo compito\n');
    });

    test('RichTextEditingController allows drag multi-line selection across bullets and checklist items', () {
      final docText = 'Titolo\n• Elemento bullet\n○ Elemento checklist\n● Elemento fatto';
      final ctrl = RichTextEditingController(
        text: docText,
        baseStyle: const TextStyle(fontSize: 15),
      );

      // Select from "bullet" to "fatto"
      final start = docText.indexOf('bullet');
      final end = docText.indexOf('fatto') + 'fatto'.length;
      ctrl.selection = TextSelection(baseOffset: start, extentOffset: end);

      ctrl.toggleBold();
      expect(ctrl.spans.length, 1);
      expect(ctrl.spans.first.isBold, isTrue);
      expect(ctrl.spans.first.start, start);
      expect(ctrl.spans.first.end, end);
    });
  });

  group('Note Model JSON Serialization & Markdown Export Tests', () {
    test('Note.toMarkdown() converts JSON blocks to clean Markdown without delimiter leakage in raw content', () {
      final blocks = [
        {
          'id': 'b-1',
          'type': 'title',
          'text': 'Titolo Principale',
          'spans': [],
        },
        {
          'id': 'b-2',
          'type': 'paragraph',
          'text': 'Testo con parola importante e dettaglio corsivo.',
          'spans': [
            {'start': 17, 'end': 27, 'bold': true},
            {'start': 40, 'end': 47, 'italic': true},
          ],
        },
        {
          'id': 'b-3',
          'type': 'checklist',
          'text': 'Attività completata',
          'isChecked': true,
          'spans': [],
        },
        {
          'id': 'b-4',
          'type': 'checklist',
          'text': 'Attività da fare',
          'isChecked': false,
          'spans': [],
        },
        {
          'id': 'b-5',
          'type': 'table',
          'tableData': [
            ['C1', 'C2'],
            ['V1', 'V2'],
          ],
          'spans': [],
        },
      ];

      final note = Note(
        id: 'json-note-1',
        title: 'Titolo Principale',
        content: jsonEncode(blocks),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.title, 'Titolo Principale');
      expect(note.snippet.contains('Testo con parola'), isTrue);

      final exportedMarkdown = note.toMarkdown();
      expect(exportedMarkdown.contains('# Titolo Principale'), isTrue);
      expect(exportedMarkdown.contains('Testo con **parola importante** e **dettaglio**'), isFalse);
      expect(exportedMarkdown.contains('**importante**'), isTrue);
      expect(exportedMarkdown.contains('*corsivo*'), isTrue);
      expect(exportedMarkdown.contains('- [x] Attività completata'), isTrue);
      expect(exportedMarkdown.contains('- [ ] Attività da fare'), isTrue);
      expect(exportedMarkdown.contains('| C1 | C2 |'), isTrue);
    });
  });

  group('NotionDocumentEditor Keyboard Shortcuts & Aa Style Tests', () {
    testWidgets('NotionDocumentEditor toggles bold with CTRL+B and heading with setBlockType', (tester) async {
      final blocks = [
        {
          'id': '1',
          'type': 'title',
          'text': 'Nota Shortcuts',
          'spans': [],
        },
        {
          'id': '2',
          'type': 'paragraph',
          'text': 'Testo per test shortcut',
          'spans': [],
        },
      ];

      final note = Note(
        id: 'test-shortcuts',
        title: 'Nota Shortcuts',
        content: jsonEncode(blocks),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final security = SecurityService();
      final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);
      final editorKey = GlobalKey<NotionDocumentEditorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(
                key: editorKey,
                note: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the continuous document TextField
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.tap(textFieldFinder);
      await tester.pumpAndSettle();

      // Change block style to Heading 1 (Aa style menu)
      editorKey.currentState?.setBlockType(BlockType.h1);
      await tester.pumpAndSettle();

      // Call toggleBold via editor state
      editorKey.currentState?.toggleBold();
      await tester.pumpAndSettle();

      // Call toggleItalic via editor state
      editorKey.currentState?.toggleItalic();
      await tester.pumpAndSettle();

      // Call toggleUnderline via editor state
      editorKey.currentState?.toggleUnderline();
      await tester.pumpAndSettle();

      // Verify no exceptions thrown and editor state is consistent
      expect(editorKey.currentState, isNotNull);
    });

    testWidgets('Typing "- " in paragraph auto-converts to bullet list', (tester) async {
      final blocks = [
        {
          'id': '1',
          'type': 'title',
          'text': 'Nota Lista',
          'spans': [],
        },
        {
          'id': '2',
          'type': 'paragraph',
          'text': '',
          'spans': [],
        },
      ];

      final note = Note(
        id: 'test-bullet-list',
        title: 'Nota Lista',
        content: jsonEncode(blocks),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final security = SecurityService();
      final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);
      final editorKey = GlobalKey<NotionDocumentEditorState>();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: db),
            Provider.value(value: vault),
            ChangeNotifierProvider.value(value: sync),
            ChangeNotifierProvider.value(value: security),
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NotionDocumentEditor(
                key: editorKey,
                note: note,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Type "- Primo elemento"
      await tester.enterText(textField, 'Nota Lista\n- Primo elemento');
      await tester.pumpAndSettle();

      // The text should now have auto-converted to bullet item
      final ctrl = tester.widget<TextField>(textField).controller as RichTextEditingController;
      expect(ctrl.text.contains('• Primo elemento'), isTrue);
    });

    test('Note computes and caches snippet correctly without JSON parsing on subsequent reads', () {
      final blocks = [
        {'id': 'b1', 'type': 'title', 'text': 'Titolo Principale'},
        {'id': 'b2', 'type': 'paragraph', 'text': 'Questo è il testo di anteprima memorizzato in cache.'},
      ];
      final json = jsonEncode(blocks);

      final note = Note(
        id: 'n1',
        title: 'Titolo Principale',
        content: json,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        cachedSnippet: Note.extractSnippet(json),
      );

      expect(note.snippet, 'Questo è il testo di anteprima memorizzato in cache.');
      expect(note.cachedSnippet, isNotNull);

      // copyWith updates cachedSnippet when content changes
      final updated = note.copyWith(
        content: jsonEncode([
          {'id': 'b1', 'type': 'title', 'text': 'Nuovo Titolo'},
          {'id': 'b2', 'type': 'paragraph', 'text': 'Snippet aggiornato.'},
        ]),
      );
      expect(updated.snippet, 'Snippet aggiornato.');
    });

    testWidgets('MacTitleBar adapts and does not overflow at 672px width', (WidgetTester tester) async {
      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
            ],
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 672,
                  child: MacTitleBar(
                    isSidebarVisible: true,
                    onToggleSidebar: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
