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
resolvedBy: null
created: 2026-10-12T18:41:27.582Z
---
# Model has no exit for a failed content save: code retries and warns

## What happens

Se la scrittura di una nota fallisce, per esempio perché il file del vault o il database non risponde, la modifica resta in attesa senza timer: non viene riscritta alla scadenza dell'attesa, ma alla consegna successiva o al passaggio dell'app in secondo piano. Alla prima scrittura fallita compare un avviso che dice che la nota non è salvata e che il salvataggio verrà ritentato. La sincronizzazione non viene avvisata finché la scrittura non riesce.

## What should happen

Il Model descrive la scrittura solo nel caso riuscito: alla scadenza dell'attesa la nota passa sempre a inattiva e la modifica viene segnalata alla sincronizzazione. Non dice nulla su cosa succede se la scrittura nel database o nel file fallisce: nessun ritento, nessun avviso. Anche il Requirement tace sull'errore. Il Task 4s0avgqr ha già scelto di ritentare e avvisare, e il codice lo fa, ma il Model non è stato aggiornato.

## Fix options

### Descrivere nel Model il ritento e l'avviso

Il Model aggiunge la regola: se la scrittura fallisce la nota resta in attesa, viene ritentata alla consegna successiva o al passaggio in secondo piano, e l'utente vede un avviso che dice che la nota non è salvata. La sincronizzazione parte solo dopo una scrittura riuscita. Il codice resta com'è. Costo: un ramo e una regola in più nel Model.

### Solo avviso, senza nuovi tentativi

Dopo un errore l'utente vede subito l'avviso, e il salvataggio riparte solo con la prossima modifica. Costo: se l'utente non modifica più la nota, la versione nuova si perde alla chiusura dell'app; il codice che oggi ritenta alla consegna successiva va cambiato.

### Nessun avviso e nessun ritento, come il Model

Il codice torna al Model: un errore di scrittura passa in silenzio e la modifica non viene ritentata fino alla modifica successiva. Costo: la perdita di una modifica passa inosservata anche quando il disco è pieno o il database non risponde.

## Where in the code

lib/core/state/notes_provider.dart (flushPendingContent, updateNoteContent); lib/main.dart (_onNotesChanged)
