---
column: done
technical: false
refs:
  - mobile-navigation/Notes list
drift: 96dg7ovq
proposal: null
agent: false
created: 2026-10-12T07:38:53.742Z
finished: 2026-10-12T10:31:33.300Z
---
# Fix code to match the Model: Swipe in trash permanently deletes notes

## What happens

Nella lista delle note del cestino, lo scorrimento verso sinistra su una nota la elimina definitivamente, dopo la conferma e lo sblocco se la nota è protetta. La schermata resta la lista; è un'azione che il Model non prevede dalla lista.

## What should happen

Lo scorrimento della lista fissa una nota o la sposta nel cestino. L'eliminazione definitiva avviene dal menu azioni della nota aperta nel cestino, e con lo svuotamento del cestino.

## Chosen option

**Aggiungere l'azione alla lista nel Model**

Il Model registra che dalla lista nel cestino lo scorrimento elimina definitivamente, con conferma. Il comportamento resta com'è e il diagramma guadagna una transizione che non cambia schermata. Serve anche descrivere la conferma.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_buildDismissibleNoteCard, confirmDismiss); lib/ui/notes_list/note_actions.dart (handle, permanentlyDelete)
