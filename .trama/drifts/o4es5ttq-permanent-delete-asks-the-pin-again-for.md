---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
proposal: null
task: lx8b641j
origin: null
critical: false
option: 1
note: null
resolvedBy: fxtjtht9
created: 2026-10-18T17:33:58.585Z
---
# Permanent delete asks the PIN again for an already unlocked note

## What happens

Eliminando definitivamente una nota protetta gia sbloccata in questa sessione, dal menu azioni nel cestino, l'app chiede di nuovo il PIN dopo la conferma. Il codice non controlla se la nota e gia sbloccata, quindi il PIN viene richiesto sempre per le note protette.

## What should happen

Il Model prevede la chiusura dell'editor verso la lista delle note dopo la conferma, senza nuovo PIN se la nota non e protetta oppure era gia sbloccata in questa sessione. Il PIN serve solo per una nota protetta non ancora sbloccata.

## Fix options

### Skip the PIN for notes already unlocked

Nel controllo prima dell'eliminazione definitiva, consentire il passaggio diretto quando la nota e gia sbloccata in questa sessione. Il codice usa il SecurityService gia disponibile nel contesto: la condizione diventa non protetta oppure sbloccata, e il PIN resta solo per le altre note protette. Il Model resta invariato e corrisponde al comportamento atteso. Il cambio tocca solo il controllo in note_actions, senza modificare altri flussi di blocco o di spostamento nel cestino.

### Keep the PIN for every protected note

Mantenere il comportamento attuale e chiarire nel Model che l'eliminazione definitiva di una nota protetta richiede sempre il PIN, anche se sbloccata in questa sessione. Questa opzione cambia il Model, quindi va decisa dallo sviluppatore prima di toccare il codice. Il comportamento osservato resta coerente con la sicurezza del blocco, ma la riga DELETE_NOTE_PERMANENTLY verso Notes list andrebbe riscritta di conseguenza.

## Where in the code

lib/ui/notes_list/note_actions.dart: confirmPermanentDelete (around lines 239-248), reached from NoteActions.handle for NoteMenuAction.permanentlyDelete (around line 194)
