import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets(
    'NotionDocumentEditor shows a plain-text note whose JSON list is not all objects',
    (tester) async {
      final note = Note(
        id: 'test-note-json-numbers',
        title: '[1]',
        content: '[1]\nTesto visibile',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: DatabaseService()),
            Provider.value(value: VaultService()),
            ChangeNotifierProvider.value(value: SecurityService()),
          ],
          child: MaterialApp(
            home: Scaffold(body: NotionDocumentEditor(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctrl =
          tester.widget<TextField>(find.byType(TextField)).controller
              as RichTextEditingController;
      expect(ctrl.text, '[1]\nTesto visibile');
    },
  );

  testWidgets(
    'NotionDocumentEditor renders Apple circular checklist and allows toggling',
    (tester) async {
      final note = Note(
        id: 'test-note-1',
        title: 'Nota Notion In-Place',
        content: '''# Nota Notion In-Place
- [ ] Comprare il latte
- [x] Fare esercizio
### Titolo sezione
Paragrafo di testo normale
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

      // 1. Unified document editor contains all checklist and paragraph items
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final ctrl =
          tester.widget<TextField>(textFieldFinder).controller
              as RichTextEditingController;

      expect(ctrl.text.contains('○ Comprare il latte'), isTrue);
      expect(ctrl.text.contains('● Fare esercizio'), isTrue);
      expect(ctrl.text.contains('Paragrafo di testo normale'), isTrue);

      // 2. Toggle the first circular checklist item (at offset of '○')
      final firstCirclePos = ctrl.text.indexOf('○');
      final toggled = ctrl.toggleChecklistAtOffset(firstCirclePos);
      expect(toggled, isTrue);
      await tester.pumpAndSettle();

      // Both items are now checked
      expect(ctrl.text.contains('● Comprare il latte'), isTrue);
      expect(ctrl.text.contains('● Fare esercizio'), isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor maps legacy-prefix spans to rendered text on load',
    (tester) async {
      final note = Note(
        id: 'legacy-span-offsets',
        title: 'Legacy spans',
        content:
            '[{"id":"legacy-spans","type":"paragraph","text":"# Titolo\\n- corpo","spans":[{"start":11,"end":16,"bold":true}]}]',
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

      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller
              as RichTextEditingController;
      expect(controller.text, 'Titolo\n• corpo');
      expect(controller.spans.single.start, 9);
      expect(controller.spans.single.end, 14);
    },
  );

  testWidgets(
    'NotionDocumentEditor adds checklist at the end when no text was ever shown',
    (tester) async {
      final note = Note(
        id: 'checklist-hidden-end',
        title: 'Nota nascosta',
        content:
            '[{"id":"t1","type":"table","tableData":[["A","B"]]},{"id":"t2","type":"table","tableData":[["C","D"]]},{"id":"t3","type":"table","tableData":[["E","F"]]}]',
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

      editorKey.currentState!.insertChecklist();
      await tester.pumpAndSettle();

      final lastField = tester.widget<TextField>(find.byType(TextField).last);
      expect((lastField.controller as RichTextEditingController).text, '○ ');
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps an empty text section between and after tables on load',
    (tester) async {
      final note = Note(
        id: 'empty-text-between-tables',
        title: 'Sezioni vuote',
        content:
            '[{"id":"t1","type":"table","tableData":[["A","B"]]},{"id":"p1","type":"paragraph","text":""},{"id":"t2","type":"table","tableData":[["C","D"]]},{"id":"p2","type":"paragraph","text":""}]',
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

      expect(
        editorKey.currentState!.debugBlocks.map((b) => b.type).toList(),
        [
          BlockType.table,
          BlockType.paragraph,
          BlockType.table,
          BlockType.paragraph,
        ],
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps indent of checklist items in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-indented-checklist',
        title: 'Legacy checklist',
        content: '# Titolo\n  ○ voce\n  - [ ] altra\n    - [x] annidata',
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

      final controller =
          tester.widget<TextField>(find.byType(TextField)).controller
              as RichTextEditingController;
      expect(controller.text, 'Titolo\n  ○ voce\n  ○ altra\n    ● annidata');
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps a text line after a table in body style in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-line-after-table',
        title: 'Legacy table',
        content: 'Prima riga\n| A | B |\n|---|---|\n| 1 | 2 |\nDopo tabella',
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

      final controllers = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .toList();
      final first = controllers.singleWhere((c) => c.text == 'Prima riga');
      final after = controllers.singleWhere((c) => c.text == 'Dopo tabella');
      expect(first.getLineStyle(0), BlockType.title);
      expect(after.getLineStyle(0), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor gives title style to first text line after leading blank lines in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-leading-blank-lines',
        title: 'Legacy blank',
        content: '\n\nPrima riga\nCorpo',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == '\n\nPrima riga\nCorpo');
      expect(ctrl.getLineStyle(0), BlockType.paragraph);
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
      expect(ctrl.getLineStyle(2), BlockType.title);
      expect(ctrl.getLineStyle(3), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor gives title style to a leading checkbox line in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-leading-checkbox',
        title: 'Legacy checkbox',
        content: '[ ] Da fare\nCorpo',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.endsWith('\nCorpo'));
      expect(ctrl.getLineStyle(0), BlockType.title);
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor drops the list symbol of a leading bullet in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-leading-bullet',
        title: 'Legacy bullet',
        content: '- Primo elemento\nCorpo',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Primo elemento\nCorpo');
      expect(ctrl.getLineStyle(0), BlockType.title);
      expect(ctrl.getLineStyle(1), BlockType.paragraph);

      ctrl.selection = const TextSelection.collapsed(
        offset: 'Primo elemento'.length,
      );
      expect(ctrl.handleEnterKey(), isTrue);
      expect(ctrl.text, 'Primo elemento\n\nCorpo');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor loads starred and dot checklist lines as to-do items in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-starred-checklist',
        title: 'Legacy checklist',
        content: 'Titolo\n* [ ] Uno\n• [ ] Due\n- ○ Tre\n- [x] Quattro',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.startsWith('Titolo'));
      // «* [ ]», «• [ ]» and «- [x]» become to-do items; «- ○» stays plain text
      expect(ctrl.text, 'Titolo\n○ Uno\n○ Due\n- ○ Tre\n● Quattro');
      expect(ctrl.getLineStyle(3), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps a checkbox without a following space as plain text when reopened',
    (tester) async {
      final note = Note(
        id: 'reopened-checkbox-no-space',
        title: 'Reopened checkbox',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n[ ]Non voce\\n[x]Neanche\\n[ ] Sì\\n[ ]\\n  - [x]"}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.startsWith('Titolo'));
      // Only «[ ] » and «[x] » with a space after the bracket are to-do items
      expect(ctrl.text, 'Titolo\n[ ]Non voce\n[x]Neanche\n○ Sì\n○ \n  ● ');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor gives title style to a leading ## or ### line in old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-leading-subheading',
        title: 'Legacy subheading',
        content: '## Primo\n### Secondo\nCorpo',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Primo\nSecondo\nCorpo');
      expect(ctrl.getLineStyle(0), BlockType.title);
      expect(ctrl.getLineStyle(1), BlockType.h3);
      expect(ctrl.getLineStyle(2), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps an indented # line as body when importing old-format notes',
    (tester) async {
      final note = Note(
        id: 'legacy-indented-heading',
        title: 'Legacy indented heading',
        content: '# Titolo\n  ## Rientrata\nCorpo',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Titolo\n  ## Rientrata\nCorpo');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps an indented # line as body when reopening a stored block',
    (tester) async {
      final note = Note(
        id: 'block-indented-heading',
        title: 'Stored indented heading',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n  # Rientrata","spans":[],"lineStyles":{"1":"paragraph"}}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Titolo\n  # Rientrata');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps an indented quote and monospace line with one sign when reopening',
    (tester) async {
      final note = Note(
        id: 'block-indented-quote-code',
        title: 'Stored indented quote',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n  > Citata\\n  ```codice","spans":[],"lineStyles":{"1":"quote","2":"code"}}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Titolo\n  > Citata\n  ```codice');
      expect(ctrl.getLineStyle(1), BlockType.quote);
      expect(ctrl.getLineStyle(2), BlockType.code);
    },
  );

  testWidgets(
    'NotionDocumentEditor loads a stored quote, numbered line without doubling its sign',
    (tester) async {
      final note = Note(
        id: 'block-typed-quote-numbered',
        title: 'Typed signs',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n> Citata\\n1. Voce","spans":[],"lineStyles":{"1":"quote","2":"numbered"}}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.startsWith('Titolo'));
      expect(ctrl.text, 'Titolo\n> Citata\n1. Voce');
      expect(ctrl.getLineStyle(1), BlockType.quote);
      expect(ctrl.getLineStyle(2), BlockType.numbered);
    },
  );

  testWidgets(
    'NotionDocumentEditor gives title style to a leading # line after an empty text block between tables',
    (tester) async {
      final note = Note(
        id: 'block-heading-after-empty-text-between-tables',
        title: 'Tabelle',
        content:
            '[{"id":"t1","type":"table","tableData":[["A","B"],["1","2"]]},{"id":"e1","type":"paragraph","text":"","isChecked":false,"spans":[]},{"id":"t2","type":"table","tableData":[["C","D"],["3","4"]]},{"id":"p1","type":"paragraph","text":"# Titolo\\nCorpo","isChecked":false,"spans":[]}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text == 'Titolo\nCorpo');
      expect(ctrl.getLineStyle(0), BlockType.title);
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor opens a block-format note with only an empty text block as an empty text section',
    (tester) async {
      final note = Note(
        id: 'block-only-empty-text',
        title: 'Vuota',
        content:
            '[{"id":"e1","type":"paragraph","text":"","isChecked":false,"spans":[]}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .single;
      expect(ctrl.text, '');
      expect(ctrl.getLineStyle(0), BlockType.paragraph);
    },
  );


  testWidgets(
    'NotionDocumentEditor turns indented dash items loaded from block format into bullets',
    (tester) async {
      final note = Note(
        id: 'block-indented-dash-item',
        title: 'Blocchi',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n  - Figlio","isChecked":false,"spans":[]}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.contains('Figlio'));
      expect(ctrl.text, 'Titolo\n  ◦ Figlio');
      expect(ctrl.getLineStyle(1), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor gives loaded bullet, quote and numbered lines their indent level and keeps the indent before the sign',
    (tester) async {
      final note = Note(
        id: 'block-indented-levels',
        title: 'Blocchi',
        content:
            '[{"id":"b1","type":"paragraph","text":"Titolo\\n  Uno\\n    Due\\n      Tre\\n  Citata\\n    Numerata","isChecked":false,"spans":[],"lineStyles":{"1":"bullet","2":"bullet","3":"bullet","4":"quote","5":"numbered"}}]',
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

      final ctrl = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller)
          .whereType<RichTextEditingController>()
          .singleWhere((c) => c.text.contains('Uno'));
      expect(
        ctrl.text,
        'Titolo\n  ◦ Uno\n    ▪ Due\n      • Tre\n  > Citata\n    1. Numerata',
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor preserves focus when user types text in a block',
    (tester) async {
      final note = Note(
        id: 'test-note-focus',
        title: 'Nota Focus Test',
        content: '''# Nota Focus Test
Paragrafo iniziale da modificare
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
            home: Scaffold(
              body: Consumer<NotesProvider>(
                builder: (context, np, _) => NotionDocumentEditor(note: note),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find continuous document TextField
      final docFinder = find.byType(TextField);
      expect(docFinder, findsOneWidget);
      await tester.tap(docFinder);
      await tester.pumpAndSettle();

      final textFieldBefore = tester.widget<TextField>(docFinder);
      expect(textFieldBefore.focusNode?.hasFocus, isTrue);

      // Type text into the field
      await tester.enterText(
        docFinder,
        '# Nota Focus Test\nParagrafo modificato con successo',
      );
      await tester.pumpAndSettle();

      // Verify it STILL has focus and text was updated
      final textFieldAfter = tester.widget<TextField>(docFinder);
      expect(textFieldAfter.focusNode?.hasFocus, isTrue);
      final ctrl = textFieldAfter.controller as RichTextEditingController;
      expect(ctrl.text.contains('Paragrafo modificato con successo'), isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor inserts interactive table, allows typing and adding rows/columns',
    (tester) async {
      final note = Note(
        id: 'test-table-note',
        title: 'Nota Tabella',
        content: '''# Nota Tabella
Testo prima della tabella
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

      // Insert table via editor state
      editorKey.currentState?.insertTable();
      await tester.pumpAndSettle();

      // Verify table widget exists
      expect(find.byType(InteractiveTableBlock), findsOneWidget);
      expect(find.text('Colonna 1'), findsWidgets);
      expect(find.text('Colonna 2'), findsWidgets);
      expect(find.text('Elemento 1'), findsOneWidget);
      expect(find.text('Elemento 2'), findsOneWidget);

      // Focus and edit a cell
      final cellFinder = find.widgetWithText(TextField, 'Elemento 1');
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      await tester.enterText(cellFinder, 'Dato Aggiornato');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Dato Aggiornato'), findsOneWidget);
      final cellWidget = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Dato Aggiornato'),
      );
      expect(cellWidget.focusNode?.hasFocus, isTrue);

      // Tap "+ Riga" button
      final addRowButton = find.text('+ Riga');
      expect(addRowButton, findsOneWidget);
      await tester.tap(addRowButton);
      await tester.pumpAndSettle();

      // Tap "+ Colonna" button
      final addColButton = find.text('+ Colonna');
      expect(addColButton, findsOneWidget);
      await tester.tap(addColButton);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'NotionDocumentEditor moves the cursor with arrow keys into and out of a table',
    (tester) async {
      final note = Note(
        id: 'test-arrow-table',
        title: 'Nota Frecce',
        content: '''# Nota Frecce

Testo prima

| A | B |
|---|---|
| 1 | 2 |

Testo dopo
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
      expect(find.byType(InteractiveTableBlock), findsOneWidget);

      // Up at the start of the text after the table enters its last cell
      final after = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text.trim() == 'Testo dopo',
      );
      expect(after, findsOneWidget);
      await tester.tap(after);
      await tester.pumpAndSettle();
      tester.widget<TextField>(after).controller!.selection =
          const TextSelection.collapsed(offset: 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.widgetWithText(TextField, '2')).focusNode
            ?.hasFocus,
        isTrue,
      );

      // Up from the first row of the table returns to the text before it
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      final before = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.controller?.text.contains('Testo prima') ?? false),
      );
      expect(
        tester.widget<TextField>(before).focusNode?.hasFocus,
        isTrue,
      );

      // Down at the end of the text before the table enters its first cell
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.widgetWithText(TextField, 'A')).focusNode
            ?.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor treats a table with the cursor in a cell as the active part',
    (tester) async {
      final note = Note(
        id: 'test-table-active',
        title: 'Nota Tabella Attiva',
        content: '''# Nota Tabella Attiva

Testo prima

| A | B |
|---|---|
| 1 | 2 |

Testo dopo
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

      // Cursor in a table cell makes the table the active part
      await tester.tap(find.widgetWithText(TextField, '2'));
      await tester.pumpAndSettle();

      // A new table goes after the active table, before the text after it
      editorKey.currentState?.insertTable();
      await tester.pumpAndSettle();

      final tables = find.byType(InteractiveTableBlock);
      expect(tables, findsNWidgets(2));
      final after = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text.trim() == 'Testo dopo',
      );
      expect(
        tester.getTopLeft(tables.at(1)).dy,
        lessThan(tester.getTopLeft(after).dy),
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor loads a remote version while a table cell has the cursor',
    (tester) async {
      const content = '''# Nota Remota Tabella

Testo prima

| A | B |
|---|---|
| 1 | 2 |

Testo dopo
''';
      final note = Note(
        id: 'test-remote-table-cell',
        title: 'Nota Remota Tabella',
        content: content,
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

      Widget app(Note n) => MultiProvider(
        providers: [
          Provider.value(value: db),
          Provider.value(value: vault),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: security),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NotionDocumentEditor(key: editorKey, note: n),
          ),
        ),
      );

      await tester.pumpWidget(app(note));
      await tester.pumpAndSettle();

      // Cursor in a table cell
      await tester.tap(find.widgetWithText(TextField, '2'));
      await tester.pumpAndSettle();

      // A remote version that differs from the last saved one is loaded anyway
      await tester.pumpWidget(
        app(note.copyWith(content: content.replaceFirst('Testo dopo', 'Testo remoto'))),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text.trim() == 'Testo remoto',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor checklist with the cursor in a table goes right after the table',
    (tester) async {
      final note = Note(
        id: 'test-checklist-table',
        title: 'Nota Checklist Tabella',
        content: '''# Nota Checklist Tabella

Testo prima

| A | B |
|---|---|
| 1 | 2 |

Testo dopo
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

      // Cursor in a table cell makes the table the active part
      await tester.tap(find.widgetWithText(TextField, '2'));
      await tester.pumpAndSettle();

      editorKey.currentState?.insertChecklist();
      await tester.pumpAndSettle();

      // The empty checklist item sits between the table and the text after it
      final tables = find.byType(InteractiveTableBlock);
      final checklist = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text.trim() == '○',
      );
      final after = find.byWidgetPredicate(
        (w) => w is TextField && w.controller?.text.trim() == 'Testo dopo',
      );
      expect(checklist, findsOneWidget);
      expect(
        tester.getTopLeft(tables.first).dy,
        lessThan(tester.getTopLeft(checklist).dy),
      );
      expect(
        tester.getTopLeft(checklist).dy,
        lessThan(tester.getTopLeft(after).dy),
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor quick menu Tabella removes only the slash and inserts the table after the section',
    (tester) async {
      final note = Note(
        id: 'test-table-replace',
        title: 'Nota Sostituzione',
        content: '',
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

      // Layout: [text section, table, text section]; the table is marked by an edit.
      editorKey.currentState?.insertTable();
      await tester.pumpAndSettle();
      final cellFinder = find.widgetWithText(TextField, 'Elemento 1');
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();
      await tester.enterText(cellFinder, 'Dato Aggiornato');
      await tester.pumpAndSettle();

      // Quick menu on the first text section: "Tabella" removes only the "/" and puts the table after it.
      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      await tester.enterText(firstSection, '/');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tabella'));
      await tester.tap(find.text('Tabella'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField).first, findsOneWidget);
      final tables = find.byType(InteractiveTableBlock);
      expect(tables, findsNWidgets(2));
      expect(
        find.descendant(
          of: tables.first,
          matching: find.text('Dato Aggiornato'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: tables.last, matching: find.text('Dato Aggiornato')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NotionDocumentEditor quick menu removes a slash command with letters of any alphabet',
    (tester) async {
      final note = Note(
        id: 'test-table-unicode-command',
        title: 'Nota Comando Unicode',
        content: '',
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

      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      await tester.enterText(firstSection, '/caffè');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tabella'));
      await tester.tap(find.text('Tabella'));
      await tester.pumpAndSettle();

      final sectionAfter = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(sectionAfter.controller?.text, isEmpty);
    },
  );

  testWidgets(
    'NotionDocumentEditor quick menu style lands on the slash line, not the last line',
    (tester) async {
      final note = Note(
        id: 'test-style-slash-line',
        title: 'Nota Stile Riga',
        content: '',
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

      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      await tester.enterText(firstSection, '/\nRiga due\nRiga tre');
      await tester.pumpAndSettle();
      // Caret goes back on the slash line, which is the first one
      final ctrl = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller!;
      ctrl.selection = const TextSelection.collapsed(offset: 0);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Intestazione'));
      await tester.tap(find.text('Intestazione'));
      await tester.pumpAndSettle();

      final sectionAfter = tester
          .widget<TextField>(find.byType(TextField).first)
          .controller! as RichTextEditingController;
      expect(sectionAfter.text, '\nRiga due\nRiga tre');
      expect(sectionAfter.getLineStyle(0), BlockType.h1);
      expect(sectionAfter.getLineStyle(1), BlockType.paragraph);
      expect(sectionAfter.getLineStyle(2), BlockType.paragraph);
    },
  );

  testWidgets(
    'NotionDocumentEditor openBlockMenu shows the quick menu without a leading slash',
    (tester) async {
      final note = Note(
        id: 'test-open-block-menu',
        title: 'Nota Menu Barra',
        content: '',
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

      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsNothing);

      editorKey.currentState?.openBlockMenu();
      await tester.pumpAndSettle();
      for (final label in [
        'Checklist',
        'Intestazione',
        'Sottointestazione',
        'Elenco',
        'Numerato',
        'Citazione',
        'Tabella',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets(
    'NotionDocumentEditor Block menu closes when Enter on a list drops the leading slash',
    (tester) async {
      final note = Note(
        id: 'test-block-menu-enter',
        title: 'Nota Menu Invio',
        content: '',
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

      // A bullet item without a slash: the Block menu opened by the button stays open only until a text edit.
      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      await tester.enterText(firstSection, '- Elemento');
      await tester.pumpAndSettle();

      editorKey.currentState?.openBlockMenu();
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsOneWidget);

      // Enter on the item is handled by the list logic, not by typed text: the menu must still close.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Tabella'), findsNothing);
    },
  );

  testWidgets(
    'NotionDocumentEditor openBlockMenu does nothing while the note is protected',
    (tester) async {
      final note = Note(
        id: 'test-open-block-menu-protected',
        title: 'Nota Protetta',
        content: '',
        isLocked: true,
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

      editorKey.currentState?.openBlockMenu();
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsNothing);

      security.unlockNote(note.id);
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsNothing);
    },
  );

  testWidgets(
    'NotionDocumentEditor openBlockMenu with no section focused focuses the last used section',
    (tester) async {
      final note = Note(
        id: 'test-open-block-menu-no-focus',
        title: 'Nota Menu Senza Focus',
        content: '',
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

      final section = find.byType(TextField).first;
      await tester.tap(section);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsNothing);

      editorKey.currentState?.openBlockMenu();
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsOneWidget);
      expect(tester.widget<TextField>(section).focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor openBlockMenu with no section focused in a long note opens under the last section',
    (tester) async {
      final content = jsonEncode([
        {'id': 'first', 'type': 'paragraph', 'text': 'Prima sezione'},
        for (var i = 0; i < 60; i++) ...[
          {'id': 'divider$i', 'type': 'divider'},
          {'id': 'section$i', 'type': 'paragraph', 'text': 'Sezione $i'},
        ],
      ]);
      final note = Note(
        id: 'test-open-block-menu-long-note',
        title: 'Nota Lunga Menu',
        content: content,
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

      editorKey.currentState?.openBlockMenu();
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsOneWidget);
      final lastSection = tester
          .widgetList<TextField>(find.byType(TextField))
          .firstWhere((field) => field.controller?.text == 'Sezione 59');
      expect(lastSection.focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor block menu closes when focus leaves its section',
    (tester) async {
      final note = Note(
        id: 'test-block-menu-focus-leave',
        title: 'Nota Focus Menu',
        content: '',
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

      // Layout: [text section, table, text section].
      editorKey.currentState?.insertTable();
      await tester.pumpAndSettle();

      final firstSection = find.byType(TextField).first;
      await tester.tap(firstSection);
      await tester.pumpAndSettle();
      await tester.enterText(firstSection, '/');
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsOneWidget);

      // Focus moves to the last text section: the menu under the first one closes.
      final lastSection = find.byType(TextField).last;
      await tester.tap(lastSection);
      await tester.pumpAndSettle();
      expect(find.text('Tabella'), findsNothing);
    },
  );

  testWidgets(
    'NotionDocumentEditor renders markdown tables with irregular row lengths without errors',
    (tester) async {
      // Markdown table with mismatched cell counts (e.g. 3 cols in header, 2 in row 1, 4 in row 2)
      final note = Note(
        id: 'irregular-table-note',
        title: 'Nota Tabella Irregolare',
        content: '''# Nota Tabella Irregolare
| A | B | C |
| --- | --- | --- |
| Solo due | celle |
| Uno | Due | Tre | Quattro |
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

      // Verify it rendered without throwing "Table contains irregular row lengths"
      expect(find.byType(InteractiveTableBlock), findsOneWidget);
      expect(find.text('Solo due'), findsOneWidget);
      expect(find.text('Quattro'), findsOneWidget);
    },
  );

  testWidgets(
    'NotionDocumentEditor maintains focus when auto-converting paragraph with - to bullet',
    (tester) async {
      final note = Note(
        id: 'test-bullet-convert',
        title: 'Nota Bullet Convert',
        content: '''# Nota Bullet Convert
Testo normale
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

      final docFinder = find.byType(TextField);
      expect(docFinder, findsOneWidget);
      await tester.tap(docFinder);
      await tester.pumpAndSettle();

      // Type "- Elemento elenco"
      await tester.enterText(
        docFinder,
        '# Nota Bullet Convert\n- Elemento elenco',
      );
      await tester.pumpAndSettle();

      // Verify it transformed to bullet and still has focus!
      final textField = tester.widget<TextField>(docFinder);
      expect(textField.focusNode?.hasFocus, isTrue);
      final ctrl = textField.controller as RichTextEditingController;
      expect(ctrl.text.contains('• Elemento elenco'), isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor renders Apple circular checkbox and toggles on tap',
    (tester) async {
      final note = Note(
        id: 'test-note-tap-check',
        title: 'Nota Checklist Tap',
        content: '''# Nota Checklist Tap
- [ ] Comprare le mele
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

      expect(ctrl.text.contains('○ Comprare le mele'), isTrue);

      // Tap circular checkbox to check
      final circlePos = ctrl.text.indexOf('○');
      ctrl.resetToggleDebounce();
      final checked = ctrl.toggleChecklistAtOffset(circlePos);
      expect(checked, isTrue);
      await tester.pumpAndSettle();

      expect(ctrl.text.contains('● Comprare le mele'), isTrue);

      // Tap again to uncheck
      ctrl.resetToggleDebounce();
      final unchecked = ctrl.toggleChecklistAtOffset(ctrl.text.indexOf('●'));
      expect(unchecked, isTrue);
      await tester.pumpAndSettle();

      expect(ctrl.text.contains('○ Comprare le mele'), isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor preserves focus when typing #tag and shows floating popup',
    (tester) async {
      final note = Note(
        id: 'test-tag-focus-note',
        title: 'Nota Tag Focus',
        content: '''# Nota Tag Focus
Scrivendo un tag qui: 
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

      final docFinder = find.byType(TextField);
      expect(docFinder, findsOneWidget);

      // Tap and gain focus
      await tester.tap(docFinder);
      await tester.pumpAndSettle();

      final textFieldBefore = tester.widget<TextField>(docFinder);
      expect(textFieldBefore.focusNode?.hasFocus, isTrue);

      // Type text ending in #tag
      await tester.enterText(
        docFinder,
        '# Nota Tag Focus\nScrivendo un tag qui: #flutter',
      );
      await tester.pump();

      // Verify focus is STILL held
      final textFieldAfter = tester.widget<TextField>(docFinder);
      expect(textFieldAfter.focusNode?.hasFocus, isTrue);

      // Verify the floating popup is displayed
      expect(find.text('TAG SUGGERITI'), findsOneWidget);
    },
  );

  testWidgets(
    'NotionDocumentEditor hides tag popup for a bare hash when there are no tags',
    (tester) async {
      final note = Note(
        id: 'test-tag-bare-hash-note',
        title: 'Nota Tag Vuota',
        content: '''# Nota Tag Vuota
Scrivendo un tag qui: 
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

      final docFinder = find.byType(TextField);
      expect(docFinder, findsOneWidget);

      await tester.tap(docFinder);
      await tester.pumpAndSettle();

      await tester.enterText(
        docFinder,
        '# Nota Tag Vuota\nScrivendo un tag qui: #',
      );
      await tester.pump();

      expect(find.text('TAG SUGGERITI'), findsNothing);
    },
  );

  testWidgets(
    'NotionDocumentEditor indents bullet item with Tab to Notion sub-bullet',
    (tester) async {
      final note = Note(
        id: 'test-note-tab',
        title: 'Nota Tab Test',
        content: '''# Nota Tab Test
• Primo elemento
• Secondo elemento
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

      final docFinder = find.byType(TextField);
      expect(docFinder, findsOneWidget);
      await tester.tap(docFinder);
      await tester.pumpAndSettle();

      final ctrl =
          tester.widget<TextField>(docFinder).controller
              as RichTextEditingController;
      // Set caret on the second bullet item
      final secondPos = ctrl.text.indexOf('Secondo elemento');
      ctrl.selection = TextSelection.collapsed(offset: secondPos);

      // Send Tab key event
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Verify it transformed into nested sub-bullet with '◦' and 2 spaces indent
      expect(ctrl.text.contains('  ◦ Secondo elemento'), isTrue);
    },
  );

  testWidgets(
    'NotionDocumentEditor keeps the active part by position after a remote reload',
    (tester) async {
      const local =
          '[{"id":"p1","type":"paragraph","text":"Uno"},'
          '{"id":"t1","type":"table","tableData":[["A","B"]]},'
          '{"id":"p2","type":"paragraph","text":"Due"},'
          '{"id":"t2","type":"table","tableData":[["C","D"]]},'
          '{"id":"p3","type":"paragraph","text":"Tre"}]';
      const remote =
          '[{"id":"p1","type":"paragraph","text":"Uno"},'
          '{"id":"t1","type":"table","tableData":[["A","B"]]},'
          '{"id":"p2","type":"paragraph","text":"Due nuova"},'
          '{"id":"t2","type":"table","tableData":[["C","D"]]},'
          '{"id":"p3","type":"paragraph","text":"Tre"}]';
      Note noteWith(String content) => Note(
        id: 'remote-reload-active-part',
        title: 'Ricaricamento remoto',
        content: content,
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

      Widget app(Note note) => MultiProvider(
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
      );

      await tester.pumpWidget(app(noteWith(local)));
      await tester.pumpAndSettle();

      // Focus the second text part: it becomes the active part.
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is TextField && (w.controller?.text ?? '') == 'Due',
        ),
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Remote update rebuilds the parts; the active part must stay the second text part.
      await tester.pumpWidget(app(noteWith(remote)));
      await tester.pumpAndSettle();

      editorKey.currentState!.insertChecklist();
      await tester.pumpAndSettle();

      final texts = tester
          .widgetList<TextField>(find.byType(TextField))
          .map((f) => f.controller!.text)
          .toList();
      expect(texts, contains('○ Due nuova'));
      expect(texts.last, 'Tre');
    },
  );

  testWidgets(
    'switching note discards the edit still waiting in the editor instead of saving it to the previous note',
    (tester) async {
      const contentA = '[{"id":"pa","type":"paragraph","text":"Uno"}]';
      const contentB = '[{"id":"pb","type":"paragraph","text":"Due"}]';
      final noteA = Note(
        id: 'switch-discard-note-a',
        title: 'Nota A',
        content: contentA,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final noteB = Note(
        id: 'switch-discard-note-b',
        title: 'Nota B',
        content: contentB,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      late DatabaseService db;
      late VaultService vault;
      late SyncService sync;
      late NotesProvider provider;
      late Directory tempDir;
      await tester.runAsync(() async {
        db = DatabaseService();
        await db.init(inMemory: true);
        tempDir = await Directory.systemTemp.createTemp('editor_switch_test_');
        vault = VaultService();
        await vault.init(customPath: tempDir.path);
        sync = SyncService(db, vault);
        provider = NotesProvider(
          dbService: db,
          vaultService: vault,
          syncService: sync,
        );
        await db.upsertNote(noteA);
        await db.upsertNote(noteB);
        await provider.init();
      });

      Widget app(Note note) => MultiProvider(
        providers: [
          Provider.value(value: db),
          Provider.value(value: vault),
          ChangeNotifierProvider.value(value: sync),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider.value(value: provider),
        ],
        child: MaterialApp(
          home: Scaffold(body: NotionDocumentEditor(note: note)),
        ),
      );

      await tester.pumpWidget(app(provider.notes.firstWhere((n) => n.id == noteA.id)));
      await tester.pumpAndSettle();

      // Type into note A and switch to note B before the 300 ms pause elapses.
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && (w.controller?.text ?? '') == 'Uno',
        ),
        'Uno scritto ora',
      );
      await tester.pump();
      await tester.pumpWidget(app(provider.notes.firstWhere((n) => n.id == noteB.id)));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && (w.controller?.text ?? '') == 'Due',
        ),
        findsOneWidget,
      );
      // The waiting edit is discarded: note A keeps its stored content.
      expect(
        provider.notes.firstWhere((n) => n.id == noteA.id).content,
        contentA,
      );

      await tester.runAsync(() async {
        provider.dispose();
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });
    },
  );
}
