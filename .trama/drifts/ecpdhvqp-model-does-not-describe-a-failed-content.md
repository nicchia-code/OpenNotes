---
status: resolved
resolution: dismissed
refs:
  - note-content-save/Waiting
proposal: null
task: null
origin: null
critical: false
option: null
note: null
created: 2026-10-13T05:21:56.133Z
---
# Model does not describe a failed content save

## What happens

Se la scrittura nel database o nel file della nota fallisce, la modifica resta in attesa e non viene scritta. Compare un avviso una sola volta: «Nota non salvata: il salvataggio verrà ritentato.» Il tentativo successivo parte solo alla prossima consegna dell'editor o quando l'app va in secondo piano; non c'è un nuovo tentativo a tempo. Quando la scrittura riesce l'avviso scompare.

## What should happen

Il Model non prevede il fallimento: l'attesa finisce sempre con la scrittura riuscita e il Model non dice che cosa succede alla modifica, né che cosa vede l'utente, se la scrittura non riesce.

## Fix options

### Descrivere il fallimento nel Model come funziona oggi

Il Model aggiunge il caso: la modifica resta in attesa, l'utente vede un avviso una sola volta, e la scrittura viene ritentata alla prossima consegna o quando l'app va in secondo piano. Costo: se l'utente smette di scrivere e non cambia app, la modifica può restare non scritta a lungo; questo va detto nel Model.

### Ritentare automaticamente dopo un intervallo

Dopo un fallimento parte un nuovo tentativo dopo un breve intervallo, come nuova transizione dell'attesa verso sé stessa. Costo: più tentativi ripetuti anche quando il disco o il database sono bloccati, e un nuovo stato di attesa del ritentativo da descrivere nel Model. La modifica viene scritta senza altre azioni dell'utente.

## Where in the code

lib/core/state/notes_provider.dart (flushPendingContent); lib/main.dart (_onNotesChanged)
