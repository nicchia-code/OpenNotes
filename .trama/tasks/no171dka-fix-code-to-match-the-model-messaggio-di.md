---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
drift: auqtfkao
proposal: null
agent: false
created: 2026-10-18T16:59:40.153Z
finished: 2026-10-18T17:28:48.537Z
---
# Fix code to match the Model: Messaggio di esportazione senza nome quando il nome salvato non ha estensione

## What happens

Quando la finestra di salvataggio restituisce un nome senza estensione, per esempio **Idee**, oppure un riferimento opaco, l'app mostra solo «Nota esportata.», senza nome del file. Il ripiego sul nome proposto dal titolo, deciso nelle correzioni precedenti, non c'è.

## What should happen

La correzione chiusa `qwjeec17` ha deciso che il messaggio mostra il nome salvato quando ha un'estensione qualunque e che il nome proposto resta per i riferimenti senza nome leggibile; un nome digitato senza estensione, come *Idee*, deve continuare a mostrare il nome proposto. La correzione `3asckbs9` ha previsto lo stesso ripiego. Il Model dice che il messaggio mostra il nome del file esportato.

## Chosen option

**Mostrare il nome salvato o il nome proposto**

Il messaggio mostra il nome restituito dal sistema quando è leggibile, anche senza estensione; se il riferimento è opaco mostra il nome proposto dal titolo, come deciso in `qwjeec17`. Costo: per un riferimento opaco il nome mostrato può non essere quello con cui il sistema ha salvato il file.

## Where in the code

lib/ui/notes_list/note_actions.dart: funzione `savedFileName` (il nome senza estensione diventa null) e ramo `NoteMenuAction.export`, messaggio «Nota esportata.» quando `savedName` è null
