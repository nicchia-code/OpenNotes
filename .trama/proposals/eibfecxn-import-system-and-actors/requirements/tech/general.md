---
description: Tecnologie, librerie e piattaforme dell'intera app; serve per qualsiasi lavoro di implementazione o build.
---

# General technology

## General
- Linguaggio Dart con Flutter; vincolo SDK Dart `^3.11.4`; versione app 1.0.0+1; package privato (non pubblicato).
- Lint: `flutter_lints` 6.x tramite `package:flutter_lints/flutter.yaml`, senza regole aggiuntive.
- Gestione dello stato con `provider` 6.1.5+1: i servizi vengono inizializzati all'avvio e poi esposti con un `MultiProvider` (servizi semplici come valori, servizi osservabili come `ChangeNotifier`).
- Persistenza locale con `sqflite` 2.4.2+1; su Linux, macOS e Windows si usa `sqflite_common_ffi` 2.4.0+3 (SQLite via FFI), usato anche per i database in memoria dei test.
- Percorsi dei file con `path_provider` 2.1.6 e `path` 1.9.1; preferenze locali con `shared_preferences` 2.5.5.
- Vault Markdown: front matter YAML letto con `yaml` 3.1.4 e scritto con `yaml_writer` 2.1.0; anteprima Markdown con `flutter_markdown` 0.7.7+1.
- Identificatori generati con `uuid` 4.6.0; hashing del PIN con `crypto` 3.0.7.
- Date e formati localizzati con `intl` 0.20.3; all'avvio viene inizializzata la localizzazione `it_IT`; l'interfaccia è in italiano.
- Cloud: `supabase_flutter` 2.17.2 (autenticazione, database Postgres con Row Level Security, storage degli allegati nel bucket `note-attachments`, Realtime sulle tabelle di note e cartelle). URL e chiave anonima di default sono incorporati e sovrascrivibili con le variabili di compilazione `SUPABASE_URL` e `SUPABASE_ANON_KEY`, e configurabili dall'utente.
- Accesso con Google via OAuth di Supabase: su desktop un server di loopback su `localhost:3000` riceve la callback (in caso di errore si ricade sul deep link); su mobile si usa il deep link `opennotes://login-callback`; sul web nessun redirect esplicito.
- Esportazione: `pdf` 3.12.0 e `printing` 5.14.3 per il PDF, `share_plus` 13.3.0 per la condivisione, `file_picker` 12.2.0 per la scelta di file e cartelle.
- Piattaforme: Android (applicationId `com.opennotes.open_notes`, SDK minimo/target di default Flutter), iOS, macOS, Linux, Windows; cartella web presente (manifest di template).
- Desktop: `window_manager` 0.5.2 con finestra senza barra di sistema (barra del titolo nascosta, barra unificata disegnata dall'app), dimensione iniziale 1280×760, minima 640×480, centrata, sfondo trasparente; su Linux la finestra GTK è senza decorazioni con titolo "OpenNotes".
- macOS: app sandbox con permessi client e server di rete e lettura/scrittura dei file scelti dall'utente (il server serve al loopback OAuth).
