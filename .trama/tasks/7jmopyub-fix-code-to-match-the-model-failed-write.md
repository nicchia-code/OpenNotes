---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination/operating-system.FILE_SAVE_DIALOG_CLOSED
drift: fb5uvqun
proposal: null
agent: false
created: 2026-10-12T14:57:05.738Z
finished: 2026-10-12T15:00:35.524Z
---
# Fix code to match the Model: Failed write of the exported Markdown file is not in the Model

## What happens

Se l'utente sceglie una posizione ma la scrittura del file fallisce (cartella di sola lettura, disco pieno, percorso non più raggiungibile), il codice non gestisce l'errore: non compare nessun messaggio, non viene creato alcun file e l'utente non sa che l'esportazione non è riuscita. Il messaggio di conferma, invece, compare solo quando la scrittura riesce.

## What should happen

Il Model descrive solo due esiti della finestra di salvataggio: file scritto con il messaggio di conferma, oppure annullamento senza effetti. Non dice cosa vede l'utente se la scrittura fallisce né se può riprovare. Il Requirement sull'esportazione non ne parla. Senza una regola, l'utente può credere che il file esista, e il comportamento non è verificabile.

## Chosen option

**Mostrare un errore**

Se la scrittura fallisce, l'app mostra un breve messaggio di errore con la causa in forma semplice, come «Nota non esportata». I dati non cambiano e l'utente può riprovare dal menu della nota. Costo: il Model deve descrivere il messaggio e il suo testo.

## Where in the code

lib/ui/notes_list/note_actions.dart, ramo di esportazione in Markdown: la scrittura del file non ha alcun trattamento dell'errore
