import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show AppExitResponse;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/database_service.dart';
import 'core/services/security_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/sync_triggers.dart';
import 'core/services/sync_log.dart';
import 'core/services/vault_service.dart';
import 'core/state/notes_provider.dart';
import 'ui/shell/adaptive_app_shell.dart';
import 'ui/shell/linux_window_resize_handles.dart';
import 'ui/theme/apple_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  // Initialize Desktop Frameless Window Manager
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 760),
      minimumSize: Size(680, 480),
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

  final connectivity = Connectivity();
  final appVisibility = AppVisibility();
  final syncTriggers = SyncTriggers(
    connectivityChanges: connectivity.onConnectivityChanged,
    checkConnectivity: connectivity.checkConnectivity,
    visibilityChanges: appVisibility.changes,
    initiallyVisible: appVisibility.isVisible,
  );
  final docsDir = await getApplicationDocumentsDirectory();
  final syncLog = SyncLog(File(p.join(docsDir.path, 'sync_log.txt')));
  final syncService = SyncService(dbService, vaultService, triggers: syncTriggers, log: syncLog);

  final authService = AuthService(syncService);

  final securityService = SecurityService();
  await securityService.init();

  final notesProvider = NotesProvider(
    dbService: dbService,
    vaultService: vaultService,
    syncService: syncService,
    securityService: securityService,
  );
  await notesProvider.init();

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

  // The cloud connection is prepared after the interface appears, so it never delays the start.
  WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(syncService.init()));
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
  if (note1 != null) await provider.togglePin(note1.id);

  await provider.createNote(
    initialTitle: 'Pianificazione & Attività',
    initialContent: jsonEncode(tableBlocks),
  );
}

class OpenNotesApp extends StatefulWidget {
  const OpenNotesApp({super.key});

  @override
  State<OpenNotesApp> createState() => _OpenNotesAppState();
}

class _OpenNotesAppState extends State<OpenNotesApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final NotesProvider _notes;
  late final AppLifecycleListener _lifecycle;
  bool _saveFailureShown = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _saveFailureBar;
  late final StreamSubscription<void> _actionFailureSub;

  @override
  void initState() {
    super.initState();
    _notes = context.read<NotesProvider>();
    _notes.addListener(_onNotesChanged);
    // One warning for each note action cancelled because its vault file could not be written.
    _actionFailureSub = _notes.actionFailures.listen((_) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Nota non salvata: l'azione è stata annullata.")),
      );
    });
    // Launch notice: the cloud stays not configured while a build variable is missing; shown once.
    final cloudNotice = context.read<SyncService>().notConfiguredMessage;
    if (cloudNotice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(cloudNotice)));
      });
    }
    // Leaving the foreground (background, or closing the window) writes the waiting edit now.
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state != AppLifecycleState.resumed) _notes.flushOnAppLeavingForeground();
      },
      onExitRequested: () async {
        await _notes.flushOnAppLeavingForeground();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _notes.removeListener(_onNotesChanged);
    _actionFailureSub.cancel();
    super.dispose();
  }

  /// Warns once per failure: the note text stays unsaved until a write succeeds. The warning goes away with the first
  /// successful write; other messages are left alone.
  void _onNotesChanged() {
    if (!_notes.contentSaveFailed) {
      _saveFailureShown = false;
      _saveFailureBar?.close();
      _saveFailureBar = null;
      return;
    }
    if (_saveFailureShown) return;
    _saveFailureShown = true;
    _saveFailureBar = _messengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Nota non salvata: il salvataggio verrà ritentato.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      title: 'OpenNotes',
      debugShowCheckedModeBanner: false,
      theme: AppleTheme.getLightTheme(),
      darkTheme: AppleTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        if (kIsWeb || !Platform.isLinux) return child!;
        return LinuxWindowResizeHandles(child: child!);
      },
      home: const AdaptiveAppShell(),
    );
  }
}
