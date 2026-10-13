---
column: done
technical: false
refs:
  - note-content-save/Waiting
drift: ndhyxayd
proposal: null
agent: false
created: 2026-10-12T08:09:28.371Z
finished: 2026-10-12T08:11:00.300Z
---
# Fix code to match the Model: Pending save overwrites note changes made during the wait

## What happens

Se mentre la modifica di una nota è in attesa di essere scritta la nota viene fissata, spostata, messa nel cestino o ripristinata, protetta o sbloccata, la scrittura finale riporta la nota com'era prima di quel comando: il cambiamento sparisce circa mezzo secondo dopo. Una nota già nel cestino torna nell'elenco, e una nota eliminata definitivamente in quella finestra ricompare.

## What should happen

Il Modello dice che la scrittura salva la nota con il nuovo contenuto e non dice cosa accade agli altri cambiamenti fatti nel frattempo. I comandi dell'elenco (fissaggio, spostamento, cestino, protezione, eliminazione) hanno un effetto proprio nel Modello, quindi la scrittura pendente non dovrebbe annullarlo. Il Modello non dice quale dei due deve valere.

## Chosen option

**Scrivere solo il contenuto**

La scrittura finale aggiorna solo contenuto, titolo, tag, anteprima e data di modifica sulla nota com'è salvata in quel momento; fissaggio, cartella, cestino e protezione restano come l'ultimo comando li ha lasciati. Costo: una lettura della nota prima della scrittura, e nel Modello va scritto che la scrittura non riporta i campi della nota.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, il timer salva la nota catturata alla consegna); lib/core/services/database_service.dart (upsertNote sostituisce la riga intera)
