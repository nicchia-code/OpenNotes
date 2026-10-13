---
column: done
technical: false
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
drift: null
proposal: null
agent: false
created: 2026-10-12T12:07:45.252Z
finished: 2026-10-12T13:55:37.162Z
---
# Fix code to match the Model: Folder create and rename do not reload the note list

Quando l'utente crea o rinomina una cartella, l'elenco delle note deve essere ricaricato e l'evento di ricarica della lista deve arrivare alla selezione della nota, come per le altre modifiche di cartelle. Oggi la creazione e la rinomina aggiornano solo l'elenco delle cartelle e i conteggi: l'elenco delle note non viene riletto. Quando il lavoro è finito, creare o rinominare una cartella ricarica le note della vista corrente e ricalcola i conteggi, con la selezione delle note che segue le regole della selezione dopo ogni ricarica.
