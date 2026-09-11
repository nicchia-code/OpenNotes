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

  testWidgets('NotionDocumentEditor renders Apple circular checklist and allows toggling', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Unified document editor contains all checklist and paragraph items
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final ctrl = tester.widget<TextField>(textFieldFinder).controller as RichTextEditingController;

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
  });

  testWidgets('NotionDocumentEditor preserves focus when user types text in a block', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
    await tester.enterText(docFinder, '# Nota Focus Test\nParagrafo modificato con successo');
    await tester.pumpAndSettle();

    // Verify it STILL has focus and text was updated
    final textFieldAfter = tester.widget<TextField>(docFinder);
    expect(textFieldAfter.focusNode?.hasFocus, isTrue);
    final ctrl = textFieldAfter.controller as RichTextEditingController;
    expect(ctrl.text.contains('Paragrafo modificato con successo'), isTrue);
  });

  testWidgets('NotionDocumentEditor inserts interactive table, allows typing and adding rows/columns', (tester) async {
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
    final cellWidget = tester.widget<TextField>(find.widgetWithText(TextField, 'Dato Aggiornato'));
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
  });

  testWidgets('NotionDocumentEditor renders markdown tables with irregular row lengths without errors', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it rendered without throwing "Table contains irregular row lengths"
    expect(find.byType(InteractiveTableBlock), findsOneWidget);
    expect(find.text('Solo due'), findsOneWidget);
    expect(find.text('Quattro'), findsOneWidget);
  });

  testWidgets('NotionDocumentEditor maintains focus when auto-converting paragraph with - to bullet', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final docFinder = find.byType(TextField);
    expect(docFinder, findsOneWidget);
    await tester.tap(docFinder);
    await tester.pumpAndSettle();

    // Type "- Elemento elenco"
    await tester.enterText(docFinder, '# Nota Bullet Convert\n- Elemento elenco');
    await tester.pumpAndSettle();

    // Verify it transformed to bullet and still has focus!
    final textField = tester.widget<TextField>(docFinder);
    expect(textField.focusNode?.hasFocus, isTrue);
    final ctrl = textField.controller as RichTextEditingController;
    expect(ctrl.text.contains('• Elemento elenco'), isTrue);
  });

  testWidgets('NotionDocumentEditor renders Apple circular checkbox and toggles on tap', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final ctrl = tester.widget<TextField>(textFieldFinder).controller as RichTextEditingController;

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
  });

  testWidgets('NotionDocumentEditor preserves focus when typing #tag and shows floating popup', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
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
    await tester.enterText(docFinder, '# Nota Tag Focus\nScrivendo un tag qui: #flutter');
    await tester.pump();

    // Verify focus is STILL held
    final textFieldAfter = tester.widget<TextField>(docFinder);
    expect(textFieldAfter.focusNode?.hasFocus, isTrue);

    // Verify the floating popup is displayed
    expect(find.text('TAG SUGGERITI'), findsOneWidget);
  });

  testWidgets('NotionDocumentEditor indents bullet item with Tab to Notion sub-bullet', (tester) async {
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
    final provider = NotesProvider(dbService: db, vaultService: vault, syncService: sync);

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
            body: NotionDocumentEditor(note: note),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final docFinder = find.byType(TextField);
    expect(docFinder, findsOneWidget);
    await tester.tap(docFinder);
    await tester.pumpAndSettle();

    final ctrl = tester.widget<TextField>(docFinder).controller as RichTextEditingController;
    // Set caret on the second bullet item
    final secondPos = ctrl.text.indexOf('Secondo elemento');
    ctrl.selection = TextSelection.collapsed(offset: secondPos);

    // Send Tab key event
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // Verify it transformed into nested sub-bullet with '◦' and 2 spaces indent
    expect(ctrl.text.contains('  ◦ Secondo elemento'), isTrue);
  });
}
