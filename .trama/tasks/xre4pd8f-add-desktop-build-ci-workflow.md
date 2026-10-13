---
column: done
technical: true
refs:
  - requirements/tech#General
drift: null
proposal: 1vybu66p
agent: false
created: 2026-10-12T07:18:08.819Z
finished: 2026-10-12T07:22:04.051Z
---
# Add desktop build CI workflow

Il progetto non ha alcun workflow GitHub Actions: non esiste la cartella .github/workflows. Va creato un unico workflow che esegue per primo il controllo del codice e i test (flutter analyze e flutter test) e, se passano, compila OpenNotes per Windows x64, macOS universale e Linux x86_64, con questi requisiti: avvio su push su main, pull request, push di tag v* e avvio manuale; Flutter fissato alla 3.41.2 stable; se il job iniziale fallisce, le build non partono; pacchetti Windows .zip, macOS .dmg creato con create-dmg e Linux AppImage creata con appimagetool su ubuntu-22.04, con nomi OpenNotes-<versione>-<sistema>-<arch>; SUPABASE_URL e SUPABASE_ANON_KEY dai segreti GitHub, obbligatori, eccetto per le pull request da fork; artefatti conservati 30 giorni; su tag v* una GitHub Release pre-release se il tag ha un suffisso; un nuovo push sullo stesso branch o PR annulla l'esecuzione in corso, mai sui tag. Fatto quando, su un push o una pull request, il workflow esegue controllo, test e le tre build, e sui tag v* pubblica la Release.
