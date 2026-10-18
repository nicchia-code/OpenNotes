---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
proposal: null
task: no171dka
origin: null
previous: qwjeec17
critical: false
option: 1
note: null
resolvedBy: igfpa73s
created: 2026-10-18T16:40:09.753Z
---
# Messaggio di esportazione senza nome quando il nome salvato non ha estensione

## What happens

Quando la finestra di salvataggio restituisce un nome senza estensione, per esempio **Idee**, oppure un riferimento opaco, l'app mostra solo «Nota esportata.», senza nome del file. Il ripiego sul nome proposto dal titolo, deciso nelle correzioni precedenti, non c'è.

## What should happen

La correzione chiusa `qwjeec17` ha deciso che il messaggio mostra il nome salvato quando ha un'estensione qualunque e che il nome proposto resta per i riferimenti senza nome leggibile; un nome digitato senza estensione, come *Idee*, deve continuare a mostrare il nome proposto. La correzione `3asckbs9` ha previsto lo stesso ripiego. Il Model dice che il messaggio mostra il nome del file esportato.

## Fix options

### Mostrare il nome salvato o il nome proposto

Il messaggio mostra il nome restituito dal sistema quando è leggibile, anche senza estensione; se il riferimento è opaco mostra il nome proposto dal titolo, come deciso in `qwjeec17`. Costo: per un riferimento opaco il nome mostrato può non essere quello con cui il sistema ha salvato il file.

### Mostrare il nome proposto quando manca l'estensione

Il messaggio mostra il nome salvato solo se ha un'estensione; altrimenti mostra il nome proposto dal titolo, e il messaggio generico resta solo per i riferimenti senza alcun nome. Costo: un nome digitato senza estensione, come *Idee*, viene sostituito dal nome proposto *Idee.md*.

### Mostrare solo il messaggio generico

Il messaggio non riporta alcun nome in nessun caso e il Model dice che l'app conferma soltanto l'esportazione. Costo: l'utente non sa con quale nome il file è stato salvato, e la correzione chiusa `qwjeec17` andrebbe riscritta.

## Where in the code

lib/ui/notes_list/note_actions.dart: funzione `savedFileName` (il nome senza estensione diventa null) e ramo `NoteMenuAction.export`, messaggio «Nota esportata.» quando `savedName` è null
