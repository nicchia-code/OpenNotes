---
column: done
technical: false
refs:
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
drift: o4es5ttq
proposal: null
agent: false
created: 2026-10-18T17:51:55.163Z
finished: 2026-10-18T18:24:03.340Z
---
# Fix code to match the Model: Permanent delete asks the PIN again for an already unlocked note

## What happens

Eliminando definitivamente una nota protetta gia sbloccata in questa sessione, dal menu azioni nel cestino, l'app chiede di nuovo il PIN dopo la conferma. Il codice non controlla se la nota e gia sbloccata, quindi il PIN viene richiesto sempre per le note protette.

## What should happen

Il Model prevede la chiusura dell'editor verso la lista delle note dopo la conferma, senza nuovo PIN se la nota non e protetta oppure era gia sbloccata in questa sessione. Il PIN serve solo per una nota protetta non ancora sbloccata.

## Chosen option

**Skip the PIN for notes already unlocked**

Nel controllo prima dell'eliminazione definitiva, consentire il passaggio diretto quando la nota e gia sbloccata in questa sessione. Il codice usa il SecurityService gia disponibile nel contesto: la condizione diventa non protetta oppure sbloccata, e il PIN resta solo per le altre note protette. Il Model resta invariato e corrisponde al comportamento atteso. Il cambio tocca solo il controllo in note_actions, senza modificare altri flussi di blocco o di spostamento nel cestino.

## Where in the code

lib/ui/notes_list/note_actions.dart: confirmPermanentDelete (around lines 239-248), reached from NoteActions.handle for NoteMenuAction.permanentlyDelete (around line 194)
