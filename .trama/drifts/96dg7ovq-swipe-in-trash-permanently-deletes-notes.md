---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Notes list
proposal: null
task: 4gibns29
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:33.742Z
---
# Swipe in trash permanently deletes notes

## What happens

Nella lista delle note del cestino, lo scorrimento verso sinistra su una nota la elimina definitivamente, dopo la conferma e lo sblocco se la nota è protetta. La schermata resta la lista; è un'azione che il Model non prevede dalla lista.

## What should happen

Lo scorrimento della lista fissa una nota o la sposta nel cestino. L'eliminazione definitiva avviene dal menu azioni della nota aperta nel cestino, e con lo svuotamento del cestino.

## Fix options

### Aggiungere l'azione alla lista nel Model

Il Model registra che dalla lista nel cestino lo scorrimento elimina definitivamente, con conferma. Il comportamento resta com'è e il diagramma guadagna una transizione che non cambia schermata. Serve anche descrivere la conferma.

### Togliere lo scorrimento nel cestino

Nel cestino lo scorrimento a sinistra non elimina nulla; per eliminare definitivamente si usa il menu della nota o lo svuotamento. Evita eliminazioni accidentali di dati, al costo di un passaggio in più per chi svuota a mano.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_buildDismissibleNoteCard, confirmDismiss); lib/ui/notes_list/note_actions.dart (handle, permanentlyDelete)
