---
description: Tecnologie, librerie e piattaforme dell'intera app; serve per qualsiasi lavoro di implementazione o build.
---

# General technology

## General
- Linguaggio Dart con Flutter; vincolo SDK Dart `^3.11.4`; versione app 1.0.0+1; package privato (non pubblicato).
- Sviluppo locale con FVM: la versione di Flutter è quella indicata in `.fvmrc`, che può essere più recente di quella della CI purché il suo Dart rispetti il vincolo SDK `^3.11.4`.
- Lint: `flutter_lints` 6.x tramite `package:flutter_lints/flutter.yaml`, senza regole aggiuntive.
- Gestione dello stato con `provider` 6.1.5+1: i servizi vengono inizializzati all'avvio e poi esposti con un `MultiProvider` (servizi semplici come valori, servizi osservabili come `ChangeNotifier`).
- Persistenza locale con `sqflite` 2.4.2+1; su Linux, macOS e Windows si usa `sqflite_common_ffi` 2.4.0+3 (SQLite via FFI), usato anche per i database in memoria dei test.
- Percorsi dei file con `path_provider` 2.1.6 e `path` 1.9.1; preferenze locali con `shared_preferences` 2.5.5.
- Vault Markdown: front matter YAML scritto con `yaml_writer` 2.1.0 (il vault non viene mai riletto); anteprima Markdown con `flutter_markdown` 0.7.7+1.
- Identificatori generati con `uuid` 4.6.0; hashing del PIN con `crypto` 3.0.7.
- Date e formati localizzati con `intl` 0.20.3; all'avvio viene inizializzata la localizzazione `it_IT`; l'interfaccia è in italiano.
- Cloud: `supabase_flutter` 2.17.2 (autenticazione, database Postgres con Row Level Security, storage degli allegati nel bucket `note-attachments`, Realtime sulle tabelle di note e cartelle). URL e chiave anonima arrivano solo dalle variabili di compilazione `SUPABASE_URL` e `SUPABASE_ANON_KEY` (`--dart-define`), senza valori incorporati nel codice e senza configurazione da parte dell'utente; in sviluppo locale si passano con `--dart-define-from-file=.env`, partendo dal modello `.env.example`, e `.env` resta fuori da git.
- Accesso con Google via OAuth di Supabase: su desktop un server di loopback su `localhost:3000` riceve la callback (in caso di errore si ricade sul deep link); su mobile si usa il deep link `opennotes://login-callback`; sul web nessun redirect esplicito.
- Schema del cloud versionato con migrazioni Supabase in `supabase/migrations/` (nomi `<timestamp>_<nome>.sql`, formato della CLI di Supabase), applicabili a un progetto esistente; `supabase/schema.sql` riporta lo schema completo risultante.
- Stato della rete con `connectivity_plus` (versione stabile più recente compatibile con l'SDK Dart del progetto); su Android il manifest dichiara anche il permesso `ACCESS_NETWORK_STATE`.
- Visibilità dell'app per la sincronizzazione: su mobile dal ciclo di vita di Flutter (`AppLifecycleListener`), su desktop dagli eventi di riduzione a icona e ripristino di `window_manager`.
- Canale realtime di Supabase con la callback di stato di `subscribe`; il rinnovo del token è lasciato alla libreria, che lo passa al canale aperto.
- Esportazione: `share_plus` 12.0.2 per la condivisione, `file_picker` 11.0.3 per la scelta di file e cartelle.
- Appunti: `super_clipboard` 0.9.1 legge le immagini dagli appunti su tutte le piattaforme (usa i binari nativi precompilati, senza toolchain Rust in locale né in CI; su Android la build richiede l'NDK); il testo si legge con il `Clipboard` di Flutter.
- Immagini incollate: ridimensionamento e ricodifica (JPEG, PNG) con `image` (versione stabile più recente compatibile con l'SDK Dart del progetto).
- Piattaforme: Android (applicationId `com.opennotes.open_notes`, SDK minimo/target di default Flutter), iOS, macOS, Linux, Windows; cartella web presente (manifest di template).
- Desktop: `window_manager` 0.5.2 con finestra senza barra di sistema (barra del titolo nascosta, barra unificata disegnata dall'app), dimensione iniziale 1280×760, minima 680×480, centrata, sfondo trasparente; su Linux la finestra GTK ha titolo "OpenNotes" e non mostra alcuna barra del titolo, né quella GTK né quella aggiunta dal compositore.
  - L'app chiama `windowManager.show()` e `windowManager.focus()` dopo il primo frame disegnato da `runApp` (callback post-frame), non nella callback di `waitUntilReadyToShow`.
- macOS: app sandbox con permessi client e server di rete e lettura/scrittura dei file scelti dall'utente (il server serve al loopback OAuth).
- macOS: la finestra di `MainMenu.xib` è visibile all'avvio come nel template di Flutter (senza `visibleAtLaunch="NO"`), perché su macOS il motore Flutter parte solo quando la finestra compare; `MainFlutterWindow` la nasconde subito con lo schema di `window_manager` (override di `order(_:relativeTo:)` che chiama `hiddenWindowAtLaunch()`) e la mostra poi l'app.

### Icona dell'app e schermata di avvio
- Sorgente dell'icona: `assets/icon/OpenNotes.png` (1280×1229, riquadro arrotondato con ombra e margini trasparenti), spostato dalla radice del repository. Non è un asset Flutter: la sezione `assets` di `pubspec.yaml` non lo elenca, né elenca i file derivati.
- Tre file derivati, ricavati una volta dal sorgente e salvati nel repository accanto a lui:
  - `assets/icon/OpenNotes-square.png`: l'immagine intera, senza ridimensionarla, centrata in un quadrato 1280×1280 con margini trasparenti;
  - `assets/icon/OpenNotes-full-bleed.png`: quadrato pieno, senza angoli arrotondati, bordo, ombra né trasparenza, ritagliato dall'interno del riquadro alla dimensione massima che ci sta (circa 876×876 px, centrato);
  - `assets/icon/OpenNotes-desktop.png`: icona di Windows e Linux nella forma del modello di Apple per le icone macOS. Tela 1024×1024 trasparente; al centro il ritaglio a tutta superficie ridimensionato a 824×824 px, con 100 px di margine trasparente per lato, ritagliato nel rettangolo arrotondato a curvatura continua della maschera Apple (raggio d'angolo di circa 185 px, non un arco di cerchio). Nessun bordo, ombra o alone disegnati: fuori dalla forma tutto è trasparente.
- Su macOS 26 e successivi l'icona dell'app non compare chiusa nel riquadro grigio che il sistema aggiunge alle icone di forma non conforme, nel Dock, nel Finder, nel Launchpad e nella finestra del DMG.
- macOS: l'icona è un file Icon Composer (`.icon`) in `macos/Runner`, impostato come icona dell'app del target Runner; macOS non ha più un set PNG `AppIcon.appiconset` né una sezione in `flutter_launcher_icons`.
  - Un solo livello: il ritaglio a tutta superficie, ingrandito fino a riempire tutta la tela di 1024×1024 px. Nessuna forma, margine o angolo disegnati: la maschera la applica il sistema.
  - Aspetto piatto: effetti vetro (Liquid Glass), riflesso e ombra del livello spenti, così l'icona resta fedele al disegno.
  - Gli aspetti scuro, trasparente e colorato li ricava il sistema dal livello unico, senza varianti dedicate.
  - Su macOS da 10.15 a 15 l'icona è l'immagine statica che Xcode ricava dal file `.icon` durante la build.
  - Il file `.icon` richiede Xcode 26 o successivo, in locale e in CI.
- Le icone di Android, iOS, Windows e web si generano con `flutter_launcher_icons` (dipendenza di sviluppo, versione stabile più recente compatibile con l'SDK Dart del progetto), configurato in `pubspec.yaml`; i file generati sono salvati nel repository e sostituiscono tutte le icone predefinite di Flutter.
  - iOS: dal ritaglio a tutta superficie, senza canale alfa; gli angoli li arrotonda il sistema.
  - Android: icona classica dal ritaglio a tutta superficie; icona adattiva con lo stesso ritaglio come livello di primo piano e come livello di sfondo.
  - Windows: dall'icona di Windows e Linux.
  - Web (favicon e icone del manifest, comprese le varianti maskable): dall'immagine quadrata con margini trasparenti.
- Linux: la finestra GTK imposta all'avvio come icona l'icona di Windows e Linux, installata nel bundle Linux insieme all'eseguibile; l'AppImage usa la stessa immagine come icona del suo file `.desktop` al posto di `web/icons/Icon-512.png`.
- Schermata di avvio di iOS e Android generata con `flutter_native_splash` (dipendenza di sviluppo, versione stabile più recente compatibile con l'SDK Dart del progetto), configurato in `pubspec.yaml`, solo per queste due piattaforme.
  - Al centro l'immagine quadrata con il riquadro arrotondato intero; fondo `#FFFFFF` in tema chiaro e `#000000` in tema scuro, secondo il tema del sistema.
  - Su Android 12 e successivi, dove il sistema ritaglia l'immagine di avvio in un cerchio, il riquadro arrotondato sta tutto dentro il cerchio, senza tagli, con gli stessi fondi.

### CI/CD (GitHub Actions)
- Un workflow GitHub Actions verifica il codice e compila l'app per Windows, macOS e Linux; Android, iOS e web non vengono compilati in CI.
- Avvio: push su `main`, pull request, push di tag `v*` e avvio manuale.
- Flutter fissato alla versione 3.41.6 del canale stable, la prima 3.41 il cui Dart (3.11.4) rispetta il vincolo SDK del progetto; la versione è scritta nel workflow e non viene letta da `.fvmrc`.
- Un job iniziale esegue `flutter analyze` e `flutter test`; se fallisce, i job di build non partono.
- Build e pacchetti, senza firma del codice (su macOS firma ad-hoc):
  - Windows x64: build release compressa in un archivio `.zip`.
  - macOS universale (arm64 + x86_64): `.dmg` creato con `create-dmg`, con collegamento ad Applicazioni.
  - Linux x86_64: AppImage creata con `appimagetool` dal bundle Flutter, compilata su `ubuntu-22.04`; le librerie GTK 3 non sono incluse.
- Il job macOS gira su un runner macOS 26 o successivo indicato per nome (non `macos-latest`) e seleziona esplicitamente Xcode 26 o successivo, necessario per compilare il file `.icon`.
- Nomi dei pacchetti: `OpenNotes-<versione>-<sistema>-<arch>`, per esempio `OpenNotes-1.2.3-windows-x64.zip`, `OpenNotes-1.2.3-macos-universal.dmg`, `OpenNotes-1.2.3-linux-x86_64.AppImage`.
- Versione: su un tag `vX.Y.Z` o `vX.Y.Z-suffisso` il nome di versione è il tag senza la `v`; altrove resta quello di `pubspec.yaml`. Il numero di build è sempre il numero dell'esecuzione del workflow. Un tag `v*` in un'altra forma fa fallire il workflow.
- `SUPABASE_URL` e `SUPABASE_ANON_KEY` vengono passati alla build dai segreti GitHub e sono obbligatori: se mancano la build fallisce. Unica eccezione le pull request da fork, che compilano senza i due valori: l'app prodotta mostra l'avviso di cloud non configurato.
- Ogni esecuzione carica i pacchetti come artefatti del workflow, conservati 30 giorni.
- Su un tag `v*` viene pubblicata subito una GitHub Release con i tre pacchetti allegati e le note generate automaticamente da GitHub; è marcata pre-release se il tag ha un suffisso.
- Un nuovo push sullo stesso branch o sulla stessa pull request annulla l'esecuzione ancora in corso; le esecuzioni sui tag non vengono mai annullate.
