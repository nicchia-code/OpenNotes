---
status: resolved
resolution: fix-code
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
proposal: null
task: 7jmopyub
origin: null
critical: false
option: 1
note: null
resolvedBy: g08cr3wn
created: 2026-10-12T14:49:24.145Z
---
# Failed write of the exported Markdown file is not in the Model

## What happens

Se l'utente sceglie una posizione ma la scrittura del file fallisce (cartella di sola lettura, disco pieno, percorso non più raggiungibile), il codice non gestisce l'errore: non compare nessun messaggio, non viene creato alcun file e l'utente non sa che l'esportazione non è riuscita. Il messaggio di conferma, invece, compare solo quando la scrittura riesce.

## What should happen

Il Model descrive solo due esiti della finestra di salvataggio: file scritto con il messaggio di conferma, oppure annullamento senza effetti. Non dice cosa vede l'utente se la scrittura fallisce né se può riprovare. Il Requirement sull'esportazione non ne parla. Senza una regola, l'utente può credere che il file esista, e il comportamento non è verificabile.

## Fix options

### Mostrare un errore

Se la scrittura fallisce, l'app mostra un breve messaggio di errore con la causa in forma semplice, come «Nota non esportata». I dati non cambiano e l'utente può riprovare dal menu della nota. Costo: il Model deve descrivere il messaggio e il suo testo.

### Riaprire la finestra di salvataggio

Se la scrittura fallisce, l'app mostra un messaggio di errore e riapre la finestra di salvataggio con lo stesso nome proposto, così l'utente può scegliere un'altra posizione. Costo: il Model deve descrivere il ciclo dei tentativi e l'uscita se l'utente rinuncia.

### Non dire nulla

Il fallimento resta silenzioso come oggi: nessun messaggio, nessun file. Costo: l'utente può credere che l'esportazione sia riuscita, e il Model deve dichiararlo in modo esplicito.

## Where in the code

lib/ui/notes_list/note_actions.dart, ramo di esportazione in Markdown: la scrittura del file non ha alcun trattamento dell'errore
