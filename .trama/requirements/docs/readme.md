---
description: Usare quando si scrive o si modifica il README, la licenza, gli screenshot o il file di esempio per l'avvio in locale.
---
# README and license

## General

### README: forma
- `README.md` alla radice del repository, scritto in inglese, sostituisce del tutto il modello generato da Flutter.
- Stile minimale: frasi brevi, una riga per ogni funzione, niente emoji e niente testo di riempimento.
- Si rivolge prima a chi vuole usare l'app e poi a chi vuole compilarla: le sezioni compaiono in quest'ordine.
  1. In cima l'icona `assets/icon/OpenNotes.png`, larga 128 px e centrata (HTML `<p align="center">`); poi il titolo `OpenNotes`, sotto la frase «A local-first notes app inspired by Apple Notes, for desktop and mobile.» e due badge: stato del workflow `.github/workflows/desktop-build.yml` e licenza MIT.
  2. Screenshots.
  3. Features.
  4. Download.
  5. Cloud sync (experimental).
  6. Known limitations.
  7. Build from source.
  8. Set up your own Supabase.
  9. License.
- Nessuna sezione su architettura, struttura del codice, Trama, CI o contributi.
- Il README non contiene mai l'URL di un progetto Supabase reale né una chiave.
- Il README non scrive un numero di versione di Flutter.

### README: contenuto delle sezioni
- **Screenshots**: l'immagine `docs/screenshots/light.png`, la finestra desktop in tema chiaro.
- **Features**: una riga per ciascuna capacità.
  - Editor con formattazione dal vivo e scorciatoie Markdown: titoli, elenchi, checklist, citazioni, tabelle, immagini e disegni a mano libera.
  - Cartelle, tag scritti nel testo, ricerca, note fissate in alto, cestino con annullamento e ripristino.
  - Note bloccate con un PIN.
  - Funziona senza rete e tiene una copia di ogni nota in una cartella vault sul dispositivo.
  - Condivisione o salvataggio di una nota come Markdown.
  - Interfaccia che si adatta da desktop a mobile, tema chiaro e scuro che segue il sistema.
  - Sincronizzazione cloud facoltativa con accesso Google (rimanda alla sezione sperimentale).
- Le Features non citano l'esportazione PDF e non descrivono i file del vault come Markdown leggibile.
- **Download**: link alla pagina `https://github.com/nicchia-code/OpenNotes/releases`, con una riga per Windows (`.zip`), macOS (`.dmg`) e Linux (`.AppImage`); per Android e iOS rimanda a «Build from source».
- **Cloud sync (experimental)**: l'app funziona del tutto senza accesso; nelle Release l'accesso con Google sincronizza le note con il progetto Supabase gestito dal maintainer; la funzione è sperimentale e non va usata per dati sensibili.
- **Known limitations**: due voci.
  - Le note bloccate non sono cifrate: il PIN nasconde solo il contenuto nell'app, che resta in chiaro sul dispositivo e nel cloud.
  - Pacchetti: nessuna build pronta per Android e iOS; il `.dmg` macOS ha solo una firma ad-hoc e non è notarizzato, quindi va aperto superando l'avviso di Gatekeeper; lo `.zip` Windows non è firmato; l'AppImage richiede GTK 3 installato sul sistema.
- **Build from source**:
  - prerequisiti: FVM, con la versione di Flutter indicata in `.fvmrc`; su Linux i pacchetti di sistema usati dalla CI (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`, `libstdc++-12-dev`);
  - copiare `.env.example` in `.env` e compilarne i valori;
  - avvio con `fvm flutter run --dart-define-from-file=.env`;
  - senza i valori l'app funziona solo in locale e mostra l'avviso di cloud non configurato.
- **Set up your own Supabase**: creare un progetto, eseguire `supabase/schema.sql`, attivare il provider Google, aggiungere agli URL di redirect `http://localhost:3000` e `opennotes://login-callback`, mettere URL e chiave anonima del progetto in `.env`.
- **License**: «MIT», con link al file `LICENSE`.

### Screenshot
- Un solo file PNG in `docs/screenshots/`, `light.png`: la finestra desktop intera con barra laterale, elenco note ed editor, in tema chiaro. Non c'è una cattura in tema scuro.
- Le catture si fanno con dati separati da quelli del developer: mai il suo database, il suo vault o il suo account.
- Le note visibili sono di esempio, inventate, senza dati personali; mostrano almeno una checklist, una tabella, dei tag e più di una cartella.

### Licenza
- File `LICENSE` alla radice con il testo della licenza MIT, intestato «Copyright (c) 2026 Luca Soda».

### File di esempio per l'avvio in locale
- `.env.example` alla radice, nel repository, con le sole righe `SUPABASE_URL=` e `SUPABASE_ANON_KEY=` senza valori.
- `.env` è escluso da git tramite `.gitignore`.
