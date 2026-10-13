---
status: approved
kind: import
base:
  system.md: 37602adf7fc5e8c4c8775617f8422716d1dd6e270ca4f35285916fca68eea697
  actors/user.md: new
  actors/operating-system.md: new
  actors/supabase.md: new
  actors/time.md: new
  requirements/data/general.md: new
  requirements/tech/general.md: new
delete: []
created: 2026-10-12T06:55:57.223Z
---
# Import: System and Actors

Importazione dal codice esistente: descrizione del System (da lib/main.dart, CHANGELOG.md e dai servizi in lib/core), gli Actor esterni (utente, timer, sistema operativo, Supabase) con gli eventi che emettono, ricavati da lib/ui, lib/core/services e lib/core/state, e le sezioni General dei requisiti tech (pubspec.yaml, pubspec.lock, cartelle android, ios, macos, linux, windows, web) e data (database_service.dart, vault_service.dart, supabase/schema.sql).

Gli Actor raccolgono tutti gli eventi esterni a cui reagiscono le Machine delle sette Feature importate nelle Proposal successive (notes, organization, editor, note-lock, cloud-sync, export, navigation).

## Doubts

- README.md:1-16 è il template Flutter ("A new Flutter project") e non descrive l'app.
- pubspec.yaml:2 e web/manifest.json:8 hanno la descrizione di template; nome `open_notes` nel manifest web, nell'etichetta Android (android/app/src/main/AndroidManifest.xml:3) e nel titolo finestra Windows (windows/runner/main.cpp:30) invece di "OpenNotes".
- Il deep link `opennotes://login-callback` usato in lib/core/services/auth_service.dart:37,40 non è dichiarato né in android/app/src/main/AndroidManifest.xml (nessun intent-filter per lo schema) né in ios/Runner/Info.plist (nessun CFBundleURLTypes): il login Google su mobile non può tornare all'app.
- Android: il permesso INTERNET è dichiarato solo nei manifest debug e profile (android/app/src/debug/AndroidManifest.xml:6, android/app/src/profile/AndroidManifest.xml:6), non in android/app/src/main/AndroidManifest.xml: nella build release la sincronizzazione Supabase e l'accesso con Google non possono raggiungere la rete.
- Windows: la finestra nativa è creata con WS_OVERLAPPEDWINDOW (windows/runner/win32_window.cpp:138); la barra di sistema viene nascosta solo da window_manager in lib/main.dart:28-35.
- lib/core/services/sync_service.dart:44-50: URL e chiave anonima Supabase di default sono hardcoded nel codice.
- supabase/schema.sql:102-114: bucket `note-attachments` pubblico e lettura consentita a tutti, quindi gli allegati sono leggibili senza essere proprietari; le policy di storage non hanno DROP IF EXISTS, quindi lo script non è rieseguibile.
- lib/core/services/vault_service.dart:32: percorso vault personalizzato supportato ma lib/main.dart lo inizializza sempre senza percorso, unico chiamante, quindi la funzione non è raggiungibile.
- lib/main.dart:63-74: le note di benvenuto vengono create dopo la sincronizzazione iniziale solo se il database è vuoto, quindi un utente già autenticato con note nel cloud non le riceve; nessun flag di "primo avvio".
- Il supporto web è dubbio: database_service/vault_service usano dart:io e la cartella documenti, non disponibili sul web; la cartella web/ è solo template.
