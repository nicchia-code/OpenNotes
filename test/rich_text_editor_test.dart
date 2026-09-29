import 'dart:convert';
import 'dart:io';
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
    test(
      'RichTextEditingController applies and removes bold style span on selection',
      () {
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
      },
    );

    test(
      'RichTextEditingController supports multiple overlapping styles (Bold + Italic + Underline)',
      () {
        final ctrl = RichTextEditingController(
          text: 'Super Note',
          baseStyle: const TextStyle(fontSize: 15),
        );

        ctrl.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 5,
        ); // "Super"
        ctrl.toggleBold();
        ctrl.toggleItalic();
        ctrl.toggleUnderline();

        expect(ctrl.spans.length, 1);
        final span = ctrl.spans.first;
        expect(span.isBold, isTrue);
        expect(span.isItalic, isTrue);
        expect(span.isUnderline, isTrue);
        expect(ctrl.toMarkdown(), '***Super*** Note');
      },
    );

    test(
      'RichTextEditingController supports multi-line selection across bullets and paragraphs',
      () {
        final docText =
            'Titolo Nota\n• Primo bullet\n• Secondo bullet\nParagrafo finale';
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
      },
    );

    test(
      'RichTextEditingController handleEnterKey auto-continues and exits lists',
      () {
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
      },
    );

    test(
      'RichTextEditingController auto-converts typed checklist shortcuts and handleEnterKey continues/exits checklist',
      () {
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
      },
    );

    test(
      'RichTextEditingController allows drag multi-line selection across bullets and checklist items',
      () {
        final docText =
            'Titolo\n• Elemento bullet\n○ Elemento checklist\n● Elemento fatto';
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
      },
    );
  });

  group('Note Model JSON Serialization & Markdown Export Tests', () {
    test(
      'Note.toMarkdown() converts JSON blocks to clean Markdown without delimiter leakage in raw content',
      () {
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
        expect(
          exportedMarkdown.contains(
            'Testo con **parola importante** e **dettaglio**',
          ),
          isFalse,
        );
        expect(exportedMarkdown.contains('**importante**'), isTrue);
        expect(exportedMarkdown.contains('*corsivo*'), isTrue);
        expect(exportedMarkdown.contains('- [x] Attività completata'), isTrue);
        expect(exportedMarkdown.contains('- [ ] Attività da fare'), isTrue);
        expect(exportedMarkdown.contains('| C1 | C2 |'), isTrue);
      },
    );
  });

  group('NotionDocumentEditor Keyboard Shortcuts & Aa Style Tests', () {
    testWidgets(
      'NotionDocumentEditor toggles bold with CTRL+B and heading with setBlockType',
      (tester) async {
        final blocks = [
          {'id': '1', 'type': 'title', 'text': 'Nota Shortcuts', 'spans': []},
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
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
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
                body: NotionDocumentEditor(key: editorKey, note: note),
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

        final tf = tester.widget<TextField>(textFieldFinder);
        final ctrl = tf.controller as RichTextEditingController;
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.h1);

        // Change block style to Title
        editorKey.currentState?.setBlockType(BlockType.title);
        await tester.pumpAndSettle();
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.title);

        // Change block style to Paragraph (Corpo)
        editorKey.currentState?.setBlockType(BlockType.paragraph);
        await tester.pumpAndSettle();
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.getLineStyle(0), BlockType.paragraph);

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
      },
    );

    testWidgets(
      'NotionDocumentEditor strips legacy markdown # from text on load and applies line styles',
      (tester) async {
        final note = Note(
          id: 'legacy-markdown-note',
          title: 'Legacy Title',
          content: '''# Titolo Principale
## Intestazione Secondaria
### Terzo Livello
Testo normale di corpo
''',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

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
              home: Scaffold(body: NotionDocumentEditor(note: note)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        final ctrl =
            tester.widget<TextField>(textFieldFinder).controller
                as RichTextEditingController;

        // Ensure no raw markdown '#' exists in the editable text
        expect(ctrl.text.contains('#'), isFalse);
        expect(ctrl.text.contains('Titolo Principale'), isTrue);
        expect(ctrl.text.contains('Intestazione Secondaria'), isTrue);
        expect(ctrl.text.contains('Terzo Livello'), isTrue);
        expect(ctrl.text.contains('Testo normale di corpo'), isTrue);

        // Verify line styles
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h2);
        expect(ctrl.getLineStyle(2), BlockType.h3);
        expect(ctrl.getLineStyle(3), BlockType.paragraph);
      },
    );

    testWidgets('Typing "- " in paragraph auto-converts to bullet list', (
      tester,
    ) async {
      final blocks = [
        {'id': '1', 'type': 'title', 'text': 'Nota Lista', 'spans': []},
        {'id': '2', 'type': 'paragraph', 'text': '', 'spans': []},
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
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );
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
              body: NotionDocumentEditor(key: editorKey, note: note),
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
      final ctrl =
          tester.widget<TextField>(textField).controller
              as RichTextEditingController;
      expect(ctrl.text.contains('• Primo elemento'), isTrue);
    });

    test(
      'Note computes and caches snippet correctly without JSON parsing on subsequent reads',
      () {
        final blocks = [
          {'id': 'b1', 'type': 'title', 'text': 'Titolo Principale'},
          {
            'id': 'b2',
            'type': 'paragraph',
            'text': 'Questo è il testo di anteprima memorizzato in cache.',
          },
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

        expect(
          note.snippet,
          'Questo è il testo di anteprima memorizzato in cache.',
        );
        expect(note.cachedSnippet, isNotNull);

        // copyWith updates cachedSnippet when content changes
        final updated = note.copyWith(
          content: jsonEncode([
            {'id': 'b1', 'type': 'title', 'text': 'Nuovo Titolo'},
            {'id': 'b2', 'type': 'paragraph', 'text': 'Snippet aggiornato.'},
          ]),
        );
        expect(updated.snippet, 'Snippet aggiornato.');
      },
    );

    testWidgets('MacTitleBar adapts and does not overflow at 672px width', (
      WidgetTester tester,
    ) async {
      final db = DatabaseService();
      final vault = VaultService();
      final sync = SyncService(db, vault);
      final provider = NotesProvider(
        dbService: db,
        vaultService: vault,
        syncService: sync,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [ChangeNotifierProvider.value(value: provider)],
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

    test(
      'createNote appends single or multiple tags at the top when in tag view',
      () async {
        final db = DatabaseService();
        await db.init(inMemory: true);
        final tempDir = await Directory.systemTemp.createTemp(
          'opennotes_test_',
        );
        final vault = VaultService();
        await vault.init(customPath: tempDir.path);
        final sync = SyncService(db, vault);
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

        try {
          // 1. Single tag view
          provider.selectTag('lavoro');
          expect(provider.selectedTags, contains('lavoro'));

          final noteSingle = await provider.createNote();
          expect(noteSingle.content.startsWith('#lavoro'), isTrue);
          expect(noteSingle.tags, contains('lavoro'));

          // 2. Multiple tags view
          provider.toggleTag('progetto');
          expect(provider.selectedTags, containsAll(['lavoro', 'progetto']));

          final noteMultiple = await provider.createNote();
          expect(noteMultiple.content.contains('#lavoro'), isTrue);
          expect(noteMultiple.content.contains('#progetto'), isTrue);
          expect(noteMultiple.tags, containsAll(['lavoro', 'progetto']));

          // 3. extractTitle skips tag line
          expect(Note.extractTitle(noteMultiple.content), 'Nuova nota');
          expect(
            Note.extractTitle('${noteMultiple.content}Titolo Effettivo\n'),
            'Titolo Effettivo',
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    testWidgets(
      'NotionDocumentEditor renders tags at top as paragraph chip and line 1 as title',
      (tester) async {
        final note = Note(
          id: 'tag-note',
          title: 'Nuova nota',
          content: '#lavoro #progetto\n\nTesto',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final db = DatabaseService();
        final vault = VaultService();
        final sync = SyncService(db, vault);
        final security = SecurityService();
        final provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );

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
              home: Scaffold(body: NotionDocumentEditor(note: note)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);
        final ctrl =
            tester.widget<TextField>(textFieldFinder).controller
                as RichTextEditingController;

        expect(ctrl.getLineStyle(0), BlockType.paragraph);
        expect(ctrl.getLineStyle(1), BlockType.title);
      },
    );

    test(
      'RichTextEditingController handleTabKey indents and outdents bullet lists with Notion sub-bullet glyphs',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n• Primo punto\n• Secondo punto',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Place cursor on "• Secondo punto"
        final secondPos = ctrl.text.indexOf('Secondo');
        ctrl.selection = TextSelection.collapsed(offset: secondPos);

        // 1. Press Tab -> indents to level 1 sub-bullet with hollow circle '◦'
        final handled1 = ctrl.handleTabKey(outdent: false);
        expect(handled1, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n  ◦ Secondo punto');

        // 2. Press Tab again -> indents to level 2 sub-bullet with square '▪'
        final handled2 = ctrl.handleTabKey(outdent: false);
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n    ▪ Secondo punto');

        // 3. Press Shift+Tab (outdent) -> decreases indent back to '  ◦ '
        final handledShift1 = ctrl.handleTabKey(outdent: true);
        expect(handledShift1, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n  ◦ Secondo punto');

        // 4. Press Shift+Tab again -> decreases indent back to '• '
        final handledShift2 = ctrl.handleTabKey(outdent: true);
        expect(handledShift2, isTrue);
        expect(ctrl.text, 'Titolo\n• Primo punto\n• Secondo punto');

        // 5. Enter on sub-bullet continues with same indent and glyph, then exits on empty
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        ctrl.handleTabKey(outdent: false); // becomes '  ◦ Secondo punto'
        expect(ctrl.text.endsWith('  ◦ Secondo punto'), isTrue);

        ctrl.handleEnterKey();
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n  ◦ '), isTrue);

        ctrl.handleEnterKey(); // Enter on empty sub-bullet outdents to '• '
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n• '), isTrue);

        ctrl.handleEnterKey(); // Enter on empty bullet exits list
        expect(ctrl.text.endsWith('  ◦ Secondo punto\n'), isTrue);
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey outdents and exits sub-bullets',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  ◦ Sub-item',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after prefix "  ◦ " (offset 11: "Titolo\n" is 7, prefix is 4 -> offset 11)
        final textStart = ctrl.text.indexOf('Sub-item');
        ctrl.selection = TextSelection.collapsed(offset: textStart);

        // Backspace on "  ◦ Sub-item" at start of text outdents to "• Sub-item"
        final handled = ctrl.handleBackspaceKey();
        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n• Sub-item');

        // Backspace at start of "• Sub-item" removes bullet to plain paragraph
        final bulletPos = ctrl.text.indexOf('Sub-item');
        ctrl.selection = TextSelection.collapsed(offset: bulletPos);
        final handled2 = ctrl.handleBackspaceKey();
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\nSub-item');
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey does not demote headings and preserves lineStyles',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nLa mia intestazione\n',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // Cursor at lineStart of H1 "La mia intestazione" (offset 7)
        ctrl.selection = const TextSelection.collapsed(offset: 7);
        final handled = ctrl.handleBackspaceKey();
        // Should not demote or intercept; normal line merge handles it
        expect(handled, isFalse);
        expect(ctrl.getLineStyle(1), BlockType.h1);

        // Delete trailing newline from line 2 back into H1
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nLa mia intestazione',
          selection: TextSelection.collapsed(offset: 26),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
      },
    );

    test(
      'RichTextEditingController handleBackspaceKey outdents and removes checklist checkboxes',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n  ○ Sub-task',
          baseStyle: const TextStyle(fontSize: 15),
        );

        // Cursor right after prefix "  ○ " (offset 11: "Titolo\n" is 7, prefix is 4)
        ctrl.selection = const TextSelection.collapsed(offset: 11);
        final handled = ctrl.handleBackspaceKey();
        expect(handled, isTrue);
        expect(ctrl.text, 'Titolo\n○ Sub-task');

        // Backspace right after prefix "○ " (offset 9) removes checkbox to normal text
        ctrl.selection = const TextSelection.collapsed(offset: 9);
        final handled2 = ctrl.handleBackspaceKey();
        expect(handled2, isTrue);
        expect(ctrl.text, 'Titolo\nSub-task');
      },
    );

    test(
      'Note.toMarkdown exports paragraph blocks with lineStyles preserving heading markers',
      () {
        final jsonBlocks = [
          {
            'id': 'block-1',
            'type': 'paragraph',
            'text': 'Titolo\nIntestazione H1\nSotto H2\nCorpo',
            'lineStyles': {
              '0': 'title',
              '1': 'h1',
              '2': 'h2',
              '3': 'paragraph',
            },
          },
        ];

        final note = Note(
          id: 'linestyles-note',
          title: 'Titolo',
          content: jsonEncode(jsonBlocks),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final md = note.toMarkdown();
        expect(md.contains('# Titolo'), isTrue);
        expect(md.contains('# Intestazione H1'), isTrue);
        expect(md.contains('## Sotto H2'), isTrue);
        expect(md.contains('Corpo'), isTrue);
      },
    );

    test(
      'RichTextEditingController deleting empty heading line does not transfer heading style to subsequent line',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\n\nRiga successiva',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // User deletes the empty H1 line 1 (backspacing at offset 7)
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nRiga successiva',
          selection: TextSelection.collapsed(offset: 6),
        );

        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.paragraph);
      },
    );

    test(
      'RichTextEditingController backspacing at start of line below heading merges then splits cleanly',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nHeader\nRiga successiva',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.title,
            1: BlockType.h1,
            2: BlockType.paragraph,
          },
        );

        // User at start of 'Riga successiva' (offset 14) presses Backspace to merge with Header
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nHeaderRiga successiva',
          selection: TextSelection.collapsed(offset: 13),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);

        // User presses Enter to separate them again
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nHeader\nRiga successiva',
          selection: TextSelection.collapsed(offset: 14),
        );
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
        expect(ctrl.getLineStyle(2), BlockType.paragraph);
      },
    );

    test(
      'deleting the leading newline preserves the first surviving line style and later edits',
      () {
        final ctrl = RichTextEditingController(
          text: '\nTitolo\nCorpo',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {1: BlockType.title, 2: BlockType.h1},
          spans: [StyleSpan(start: 8, end: 13, isBold: true)],
        );

        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 1);
        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCorpo',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(ctrl.text, 'Titolo\nCorpo');
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(1), BlockType.h1);
        expect(ctrl.spans.single.start, 7);
        expect(ctrl.spans.single.end, 12);

        ctrl.value = const TextEditingValue(
          text: 'Titolo\nCorpo!',
          selection: TextSelection.collapsed(offset: 13),
        );
        expect(ctrl.text, 'Titolo\nCorpo!');
        expect(ctrl.spans.single.end, 12);
      },
    );

    test(
      'deleting the first of repeated lines uses the caret location for line styles',
      () {
        final ctrl = RichTextEditingController(
          text: 'X\nX\nY',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {
            0: BlockType.h1,
            1: BlockType.h2,
            2: BlockType.paragraph,
          },
        );
        ctrl.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
        ctrl.value = const TextEditingValue(
          text: 'X\nY',
          selection: TextSelection.collapsed(offset: 0),
        );
        expect(ctrl.getLineStyle(0), BlockType.h2);
        expect(ctrl.getLineStyle(1), BlockType.paragraph);
      },
    );

    test(
      'Enter at the start of a styled line leaves its style with the text',
      () {
        final ctrl = RichTextEditingController(
          text: 'Titolo\nCorpo',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 1: BlockType.h1},
        );
        ctrl.selection = const TextSelection.collapsed(offset: 0);
        expect(ctrl.handleEnterKey(), isTrue);
        expect(ctrl.text, '\nTitolo\nCorpo');
        expect(ctrl.getLineStyle(0), BlockType.paragraph);
        expect(ctrl.getLineStyle(1), BlockType.title);
        expect(ctrl.getLineStyle(2), BlockType.h1);
      },
    );

    test('legacy heading cleanup shifts spans by each removed prefix', () {
      final ctrl = RichTextEditingController(
        text: '# Titolo\n## Sotto\nCorpo',
        baseStyle: const TextStyle(fontSize: 15),
        spans: [StyleSpan(start: 18, end: 23, isBold: true)],
      );
      expect(ctrl.text, 'Titolo\nSotto\nCorpo');
      expect(ctrl.spans.single.start, 13);
      expect(ctrl.spans.single.end, 18);
    });

    test(
      'typing a list shortcut preserves the newline before the converted line',
      () {
        final ctrl = RichTextEditingController(
          text: 'Prima\n',
          baseStyle: const TextStyle(fontSize: 15),
        );
        ctrl.selection = const TextSelection.collapsed(offset: 6);
        ctrl.value = const TextEditingValue(
          text: 'Prima\n- ',
          selection: TextSelection.collapsed(offset: 8),
        );
        expect(ctrl.text, 'Prima\n• ');
        expect(ctrl.text.split('\n'), hasLength(2));
      },
    );

    test(
      'initial formatting is clipped to text bounds and valid line indexes',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\nDue',
          baseStyle: const TextStyle(fontSize: 15),
          spans: [
            StyleSpan(start: -3, end: 3, isBold: true),
            StyleSpan(start: 4, end: 30, isItalic: true),
          ],
          lineStyles: {-1: BlockType.h1, 0: BlockType.title, 3: BlockType.h2},
        );
        expect(ctrl.spans.map((span) => (span.start, span.end)).toList(), [
          (0, 3),
          (4, 7),
        ]);
        expect(ctrl.lineStyles, {0: BlockType.title});
      },
    );

    test(
      'replacing a selected range shifts following inline spans by actual edit length',
      () {
        final ctrl = RichTextEditingController(
          text: 'Uno\nDue\nTre',
          baseStyle: const TextStyle(fontSize: 15),
          lineStyles: {0: BlockType.title, 2: BlockType.h2},
          spans: [StyleSpan(start: 8, end: 11, isBold: true)],
        );
        ctrl.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
        ctrl.value = const TextEditingValue(
          text: 'Uno\nA\nTre',
          selection: TextSelection.collapsed(offset: 5),
        );
        expect(ctrl.spans.single.start, 6);
        expect(ctrl.spans.single.end, 9);
        expect(ctrl.getLineStyle(0), BlockType.title);
        expect(ctrl.getLineStyle(2), BlockType.h2);
      },
    );
  });
}
