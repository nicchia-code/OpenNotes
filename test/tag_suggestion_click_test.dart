import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
import 'package:provider/provider.dart';

/// Keeps the editor's saves in memory so no database timers outlive the test.
class _NoSaveNotesProvider extends NotesProvider {
  _NoSaveNotesProvider({
    required super.dbService,
    required super.vaultService,
    required super.syncService,
  });

  @override
  void updateNoteContent(String noteId, String newContent) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  testWidgets('mouse click on the Crea tag suggestion inserts the tag', (
    tester,
  ) async {
    final dbService = DatabaseService();
    final vaultService = VaultService();
    final tempDir = await tester.runAsync(() async {
      await dbService.init(inMemory: true);
      final dir = await Directory.systemTemp.createTemp('tag_click_test_');
      await vaultService.init(customPath: dir.path);
      return dir;
    });
    final notesProvider = NotesProvider(
      dbService: dbService,
      vaultService: vaultService,
      syncService: SyncService(dbService, vaultService),
    );

    final note = Note(
      id: 'tag-click',
      title: 'Tag click',
      content: 'ciao',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: dbService),
          Provider.value(value: vaultService),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider.value(value: notesProvider),
        ],
        child: MaterialApp(
          home: Scaffold(body: NotionDocumentEditor(note: note)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField).first;
    await tester.enterText(field, 'ciao #wo');
    await tester.pumpAndSettle();

    final ctrl =
        tester.widget<TextField>(field).controller as RichTextEditingController;
    final crea = find.text('Crea #wo');
    expect(crea, findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(crea));
    await mouse.down(tester.getCenter(crea));
    await tester.pump();
    await mouse.up();
    await tester.pumpAndSettle();

    expect(ctrl.text, 'ciao #wo ');
    expect(ctrl.selection.baseOffset, 'ciao #wo '.length);
    expect(find.text('Crea #wo'), findsNothing);

    notesProvider.dispose();
    await tester.runAsync(() => tempDir!.delete(recursive: true));
  });

  testWidgets('tag menu closes when its section is merged away', (
    tester,
  ) async {
    final note = Note(
      id: 'tag-merge',
      title: 'Tag merge',
      content: 'uno',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final editorKey = GlobalKey<NotionDocumentEditorState>();

    final dbService = DatabaseService();
    final vaultService = VaultService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: dbService),
          Provider.value(value: vaultService),
          ChangeNotifierProvider.value(value: SecurityService()),
          ChangeNotifierProvider<NotesProvider>.value(
            value: _NoSaveNotesProvider(
              dbService: dbService,
              vaultService: vaultService,
              syncService: SyncService(dbService, vaultService),
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NotionDocumentEditor(key: editorKey, note: note),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Layout: "uno", then two images removed, leaving two adjacent empty sections after it.
    editorKey.currentState!.insertImage('a.png');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rimuovi immagine'));
    await tester.pumpAndSettle();
    editorKey.currentState!.insertImage('b.png');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Rimuovi immagine'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    final middle = fields.at(1);
    await tester.enterText(middle, 'due #wo');
    await tester.pumpAndSettle();
    expect(find.text('Crea #wo'), findsOneWidget);

    // Caret at the start of the middle section, then Backspace merges it into the first one.
    await tester.tap(middle);
    await tester.pumpAndSettle();
    final ctrl =
        tester.widget<TextField>(middle).controller as RichTextEditingController;
    ctrl.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Crea #wo'), findsNothing);
  });
}
