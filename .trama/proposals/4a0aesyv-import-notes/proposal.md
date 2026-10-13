---
status: approved
kind: import
requires:
  - eibfecxn
  - 5tgfb0x4
  - bg03sfzb
  - 3b5s3tbv
base:
  notes/feature.md: new
  notes/note.md: new
  requirements/data/notes.md: new
  requirements/rules/notes.md: new
delete: []
created: 2026-10-12T06:57:42.250Z
---
# Import: Notes

Importazione della Feature notes dal codice: ciclo di vita della nota (creazione, note di benvenuto, fissaggio, protezione, spostamento, duplicazione, cestino con annullamento, ripristino, eliminazione definitiva, svuotamento del cestino). Fonti: lib/core/state/notes_provider.dart, lib/core/models/note_model.dart, lib/core/services/database_service.dart, lib/main.dart, lib/ui/notes_list/ (note_actions.dart, note_action_menu.dart, folder_picker.dart, note_card.dart), test/note_actions_test.dart, test/tags_test.dart, supabase/schema.sql.

## Doubts

- Fissaggio di note nel cestino: il menu non lo offre (lib/ui/notes_list/note_action_menu.dart:18-23), ma lo scorrimento verso destra nella vista Cestino chiama togglePin senza controlli (lib/ui/mobile/mobile_notes_list_screen.dart:400-403; lib/core/state/notes_provider.dart:304-317): una nota nel cestino può diventare fissata.
- Protezione di note nel cestino: il pulsante lucchetto della barra desktop agisce sulla nota selezionata anche nella vista Cestino (lib/ui/shell/adaptive_app_shell.dart:119-123), e toggleLock non controlla il cestino (lib/core/state/notes_provider.dart:320-333).
- Il comando Elimina della barra desktop su una nota già nel cestino la sposta di nuovo nel cestino (nuova data di eliminazione e avviso "Nota spostata nel cestino") invece di proporre l'eliminazione definitiva (lib/ui/shell/adaptive_app_shell.dart:70-73).
- Ordine di eliminazione definitiva/svuotamento: la cancellazione cloud viene accodata e la sincronizzazione avviata senza attenderla prima di eliminare la riga locale (lib/core/state/notes_provider.dart:439-462; lib/core/services/sync_service.dart:353-375); la sincronizzazione concorrente rilegge le note locali non sincronizzate, compresa quella non ancora eliminata, e può reinviarla al cloud dopo averla cancellata (lib/core/services/sync_service.dart:306-322), facendola poi riapparire.
- Note di benvenuto scartate per titolo: create offline vengono accodate e inviate al cloud nel passo 1 della sincronizzazione (lib/core/services/sync_service.dart:235-272) prima dello scarto per titolo al passo 3 (righe 309-316), che quindi vede sempre note nel cloud; poi il passo 4 le riscarica (righe 327-335): lo scarto è inefficace e le note di esempio finiscono nel cloud. Inoltre elimina qualunque nota dell'utente mai sincronizzata con quei titoli esatti, anche modificata.
- Le note di benvenuto vengono ricreate a ogni avvio se tutte le note sono nel cestino: il controllo conta solo le note fuori dal cestino (lib/main.dart:72-75; lib/core/services/database_service.dart:128).
- createNote non ricava titolo né tag dal contenuto iniziale (lib/core/state/notes_provider.dart:243-252): le note di benvenuto nascono senza tag finché non vengono modificate.
- L'espressione dei tag accetta solo lettere ASCII (lib/core/models/note_model.dart:379): il tag `#produttività` della nota di esempio (lib/main.dart:205) diventa `produttivit`.
- Contenuto che inizia con `[` ma non è JSON (es. "[ ] compito"): il titolo diventa sempre "Nuova nota" (lib/core/models/note_model.dart:72-104), mentre anteprima e tag ripiegano sull'analisi del testo (righe 129-156, 382-415).
- Un unico timer di salvataggio per tutte le note (lib/core/state/notes_provider.dart:294-300): modificare un'altra nota entro 400 ms annulla il salvataggio della prima, e dispose cancella un salvataggio in sospeso (riga 512); la modifica resta solo in memoria.
- Il salvataggio del contenuto non controlla il cestino (lib/core/state/notes_provider.dart:270-301; lib/ui/editor/notion_document_editor.dart:577): non ho determinato se l'editor di una nota nel cestino sia in sola lettura; modellato come modificabile.
- Il titolo della copia (" (copia)") non è troncato a 60 caratteri (lib/core/state/notes_provider.dart:390), a differenza del titolo ricavato.
- L'eliminazione di una cartella sposta in "Note" anche le note nel cestino, senza aggiornare la data di modifica, senza riscrivere il file nell'archivio e senza accodare la sincronizzazione (lib/core/services/database_service.dart:230-240): il cloud mantiene la cartella vecchia.
- Il trigger del cloud riscrive updated_at a ogni aggiornamento (supabase/schema.sql:51-54), quindi il confronto "versione locale più recente" usa date del server contro date del dispositivo.
- Svuotamento del cestino: il PIN è chiesto solo se tra le note mostrate (eventualmente filtrate dalla ricerca) ce n'è una protetta (lib/ui/notes_list/notes_list_view.dart:353; lib/ui/mobile/mobile_notes_list_screen.dart:85), ma emptyTrash elimina tutte le note del cestino (lib/core/state/notes_provider.dart:453).
- Il selettore di cartelle esclude Tutte le note e Cestino (lib/ui/notes_list/folder_picker.dart:10-15), ma quegli identificativi virtuali non sono mai nell'elenco delle cartelle del database: filtro apparentemente inutile.
- L'anteprima "~90 caratteri" non è troncata: il testo si ferma al primo blocco/riga che supera 90 caratteri e può essere molto più lungo (lib/core/models/note_model.dart:147,179).
