import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'core/services/auth_service.dart';
import 'core/services/database_service.dart';
import 'core/services/security_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/vault_service.dart';
import 'core/state/notes_provider.dart';
import 'ui/shell/adaptive_app_shell.dart';
import 'ui/theme/apple_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  // Initialize Desktop Frameless Window Manager
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 760),
      minimumSize: Size(640, 480),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Core Services
  final dbService = DatabaseService();
  await dbService.init();

  final vaultService = VaultService();
  await vaultService.init();

  final syncService = SyncService(dbService, vaultService);
  await syncService.init();

  final authService = AuthService();

  final securityService = SecurityService();
  await securityService.init();

  final notesProvider = NotesProvider(
    dbService: dbService,
    vaultService: vaultService,
    syncService: syncService,
  );
  await notesProvider.init();

  // If user is already authenticated from previous session, sync cloud notes first
  if (syncService.isAuthenticated) {
    try {
      await syncService.syncNow();
    } catch (e) {
      debugPrint('Initial startup sync error: $e');
    }
  }

  // Populate sample note if first launch and no notes exist
  final existingNotes = await dbService.getNotes();
  if (existingNotes.isEmpty) {
    await _createWelcomeNotes(notesProvider);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: dbService),
        Provider.value(value: vaultService),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: securityService),
        ChangeNotifierProvider.value(value: notesProvider),
      ],
      child: const OpenNotesApp(),
    ),
  );
}

Future<void> _createWelcomeNotes(NotesProvider provider) async {
  final welcomeBlocks = [
    {
      'id': 'b-title',
      'type': 'title',
      'text': 'Benvenuto in OpenNotes',
      'spans': [],
    },
    {
      'id': 'b-intro',
      'type': 'paragraph',
      'text': 'OpenNotes è un editor di note potente con formattazione live WYSIWYG e supporto Markdown.',
      'spans': [
        {'start': 0, 'end': 9, 'bold': true},
        {'start': 61, 'end': 68, 'italic': true},
      ],
    },
    {
      'id': 'b-h1',
      'type': 'h2',
      'text': 'Scorciatoie & Comandi Rapidi:',
      'spans': [],
    },
    {
      'id': 'b-c1',
      'type': 'checklist',
      'text': 'CTRL+B : Applica o rimuovi Grassetto',
      'isChecked': true,
      'spans': [{'start': 0, 'end': 6, 'bold': true}],
    },
    {
      'id': 'b-c2',
      'type': 'checklist',
      'text': 'CTRL+I : Applica o rimuovi Corsivo',
      'isChecked': true,
      'spans': [{'start': 0, 'end': 6, 'italic': true}],
    },
    {
      'id': 'b-c3',
      'type': 'checklist',
      'text': 'CTRL+U : Applica o rimuovi Sottolineato',
      'isChecked': true,
      'spans': [{'start': 0, 'end': 6, 'underline': true}],
    },
    {
      'id': 'b-c4',
      'type': 'checklist',
      'text': 'Pulsante Aa : Menu stili (Titolo, Intestazione, Monospazio, Elenchi)',
      'isChecked': true,
      'spans': [{'start': 0, 'end': 11, 'bold': true}],
    },
    {
      'id': 'b-c5',
      'type': 'checklist',
      'text': 'Condividi > Esporta come Markdown (.md)',
      'isChecked': false,
      'spans': [],
    },
    {
      'id': 'b-quote',
      'type': 'quote',
      'text': 'Puoi esportare in qualsiasi momento le tue note in formato Markdown standard (.md) dal menu di condivisione.',
      'spans': [{'start': 48, 'end': 71, 'bold': true}],
    },
    {
      'id': 'b-tags',
      'type': 'paragraph',
      'text': '#note #opennotes',
      'spans': [],
    },
  ];

  final tableBlocks = [
    {
      'id': 'tb-title',
      'type': 'title',
      'text': 'Pianificazione & Attività',
      'spans': [],
    },
    {
      'id': 'tb-intro',
      'type': 'paragraph',
      'text': 'Esempio di tabella nativa e checklist di produttività:',
      'spans': [],
    },
    {
      'id': 'tb-table',
      'type': 'table',
      'tableData': [
        ['Attività', 'Stato', 'Priorità'],
        ['Completare interfaccia note', 'Completato', 'Alta'],
        ['Scorciatoie standard CTRL+B/I/U', 'Attive', 'Alta'],
        ['Esportazione Markdown', 'Pronta', 'Media'],
      ],
      'spans': [],
    },
    {
      'id': 'tb-c1',
      'type': 'checklist',
      'text': 'Seleziona una parola e premi CTRL+B per metterla in grassetto',
      'isChecked': true,
      'spans': [{'start': 30, 'end': 36, 'bold': true}],
    },
    {
      'id': 'tb-c2',
      'type': 'checklist',
      'text': 'Usa il menu Aa per trasformare un paragrafo in Titolo o Elenco numerato',
      'isChecked': false,
      'spans': [{'start': 12, 'end': 14, 'bold': true}],
    },
    {
      'id': 'tb-tags',
      'type': 'paragraph',
      'text': '#todo #produttività',
      'spans': [],
    },
  ];

  final note1 = await provider.createNote(
    initialTitle: 'Benvenuto in OpenNotes',
    initialContent: jsonEncode(welcomeBlocks),
  );
  await provider.togglePin(note1.id);

  await provider.createNote(
    initialTitle: 'Pianificazione & Attività',
    initialContent: jsonEncode(tableBlocks),
  );
}

class OpenNotesApp extends StatelessWidget {
  const OpenNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenNotes',
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.getLightTheme(),
      darkTheme: AppleTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      home: const AdaptiveAppShell(),
    );
  }
}
