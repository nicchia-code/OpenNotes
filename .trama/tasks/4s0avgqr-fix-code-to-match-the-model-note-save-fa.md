---
column: done
technical: false
refs:
  - note-content-save/Waiting
drift: i9k5lt8m
proposal: null
agent: false
created: 2026-10-12T14:57:05.711Z
finished: 2026-10-12T15:00:57.736Z
---
# Fix code to match the Model: Note save failure is not described in the Model

## What happens

Se la scrittura di una nota fallisce, per esempio perché il file del vault non si può scrivere o il database rifiuta la modifica, il nuovo testo resta visibile nell'editor e nell'elenco, ma non viene salvato: il database e il file mantengono la versione precedente, la sincronizzazione non viene avvisata e l'utente non vede alcun avviso. La scrittura non viene ritentata finché non parte un'altra scrittura. Se il file riesce e il database no, il file contiene il testo nuovo e il database quello vecchio. Se l'app si chiude prima di una nuova modifica, il testo si perde.

## What should happen

Il Model descrive il salvataggio solo nel caso riuscito: la scrittura in attesa passa a inattivo e viene segnalata alla sincronizzazione. Non dice cosa succede quando la scrittura nel database o nel file fallisce: se la modifica va ritentata, se l'utente va avvisato, se la sincronizzazione deve partire comunque. Il Requirement fissa tempi e campi scritti, ma nemmeno lui dice nulla sull'errore. Il caso cambia ciò che l'utente vede rispetto a ciò che resta salvato, quindi serve una regola.

## Chosen option

**Ritentare e avvisare**

Se la scrittura fallisce, la nota resta in attesa e la scrittura viene ritentata alla consegna successiva o al passaggio in background. Se l'errore continua, l'utente vede un avviso che dice che la nota non è salvata. La sincronizzazione parte solo dopo una scrittura riuscita. Costo: un avviso in più nei rari casi di errore del disco o del database.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, timer della scrittura); lib/core/services/vault_service.dart (saveNote)
