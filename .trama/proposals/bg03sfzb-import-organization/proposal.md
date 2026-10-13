---
status: approved
kind: import
requires:
  - eibfecxn
  - 3b5s3tbv
base:
  organization/feature.md: new
  organization/folder.md: new
  organization/note-browser.md: new
  organization/note-selection.md: new
  requirements/data/organization.md: new
  requirements/rules/organization.md: new
delete: []
created: 2026-10-12T06:57:41.022Z
---
# Import: Organization

Importazione della Feature organization dal codice: cartelle (di sistema e dell'utente), filtri dell'elenco per cartella, tag, cestino e ricerca, nota selezionata e conteggi. Fonti: lib/core/models/folder_model.dart, tag_model.dart, lib/core/state/notes_provider.dart, lib/core/services/database_service.dart, lib/ui/sidebar/, lib/ui/mobile/mobile_folders_screen.dart, test/tags_test.dart, supabase/schema.sql.

## Doubts

- Le cartelle non vengono mai messe in coda per il cloud: la sincronizzazione sa inviare cartelle (lib/core/services/sync_service.dart:273-284) ma solo le note vengono accodate (sync_service.dart:353-370); creazione, rinomina ed eliminazione (lib/core/state/notes_provider.dart:465-500) restano locali, mentre le note inviate portano il riferimento a cartelle che sugli altri dispositivi non esistono.
- La sincronizzazione completa scarica le cartelle remote ma non elimina quelle locali assenti nel cloud, e le sovrascrive senza confrontare le date, a differenza delle note (sync_service.dart:217-220, 337-341).
- L'eliminazione remota in tempo reale (sync_service.dart:204-213) non passa dal navigatore: se la cartella è aperta la vista resta su una cartella inesistente (il ritorno a "Tutte le note" è solo in notes_provider.dart:492-499).
- Cartelle annidate: il commento di lib/core/models/folder_model.dart:2 dice "Supports nested subfolders" e la creazione accetta una cartella superiore (notes_provider.dart:465), il selettore "Sposta in…" mostra un albero (lib/ui/notes_list/folder_picker.dart:88-126), ma nessuna interfaccia crea sottocartelle, barra laterale e schermata Cartelle sono piatte, e l'eliminazione non aggiorna le sottocartelle (lib/core/services/database_service.dart:230-240).
- La cartella "Note rapide" (folder_model.dart:101) è codice morto: usata solo come caso di ripiego nella creazione di una nota (notes_provider.dart:224), mai selezionabile né memorizzata.
- Il dialogo di conferma su mobile dice "Tutte le note contenute in questa cartella verranno eliminate" (lib/ui/sidebar/folder_dialog.dart:81) ma il codice le sposta nella cartella "Note" (database_service.dart:233-239).
- Su desktop la cartella si elimina dal menu senza conferma e non si può rinominare (lib/ui/sidebar/sidebar_view.dart:240-255); la rinomina esiste solo su mobile (lib/ui/mobile/mobile_folders_screen.dart:137-141).
- Le note spostate dall'eliminazione di una cartella (anche quelle nel cestino) non cambiano data di modifica, file Markdown né coda di sincronizzazione (database_service.dart:233-239; notes_provider.dart:492-499): nel cloud e nel vault restano nella vecchia cartella.
- L'eliminazione nell'archivio sposta le note anche quando la cartella è di sistema e quindi non viene eliminata (database_service.dart:232-239), per esempio su un'eliminazione remota.
- Su mobile toccare un tag nella schermata Cartelle applica la selezione due volte (mobile_folders_screen.dart:186-187 e lib/ui/shell/adaptive_app_shell.dart:212-213): la seconda annulla la prima e si apre "Tutte le note" senza filtro; anche la cartella viene selezionata due volte (innocuo).
- Il filtro per tag confronta `#tag` come sottostringa del contenuto (database_service.dart:155-159): `#lavoro` trova anche le note che hanno solo `#lavoro-casa` o `#lavorone`, cioè ogni tag che inizia allo stesso modo.
- La ricerca e il filtro per tag guardano il contenuto grezzo (database_service.dart:155-167): nei documenti a blocchi trovano anche le parole della struttura (per esempio "paragraph", "type"), e trovano il testo e i tag delle note bloccate, il cui contenuto non è cifrato.
- L'elenco dei tag non viene aggiornato dopo cestino, ripristino, spostamento, eliminazione definitiva o svuotamento del cestino (notes_provider.dart:303-460 chiamano solo il ricaricamento delle note): tag e conteggi restano vecchi fino al prossimo salvataggio o sincronizzazione.
- L'ordinamento delle cartelle usa il confronto binario di SQLite (database_service.dart:218), quindi i nomi in maiuscolo precedono quelli in minuscolo, mentre il selettore ordina senza distinzione (folder_picker.dart:94-96).
- La rinomina cerca la cartella senza protezione (notes_provider.dart:482): se la cartella è sparita nel frattempo l'operazione fallisce con un errore.
- Il cambio di vista, tag o ricerca avvia il ricaricamento senza attenderlo (notes_provider.dart:160-211): con digitazione rapida risultati più vecchi potrebbero arrivare dopo quelli nuovi; comportamento effettivo non determinato.
- Spostando nel cestino una nota che non è quella selezionata (per esempio dal menu contestuale), la selezione salta comunque alla nota vicina a quella spostata (notes_provider.dart:336-353).
- Il commento "Auto-select first note if available on desktop/tablet" (notes_provider.dart:84) contraddice il codice, che seleziona la prima nota anche su mobile, all'avvio e a ogni ricarica (notes_provider.dart:149-154).
- Il metodo per svuotare i tag selezionati senza cambiare vista (notes_provider.dart:196-199) non ha chiamanti: l'interfaccia usa la selezione di un tag vuoto, che riporta anche a "Tutte le note".
```
