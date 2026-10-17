---
column: done
technical: false
refs:
  - pending-change/Pending
  - requirements/data#pending-change
drift: null
proposal: null
agent: false
created: 2026-10-17T17:50:53.634Z
finished: 2026-10-17T18:08:49.731Z
---
# Fix code to match the Requirements: Queued folder delete carries the whole folder, not only its id

La cancellazione di una cartella in coda deve portare solo l'identificativo della cartella, come chiede il Requirement dei dati della coda per ogni cancellazione. Oggi porta tutti i campi della cartella. Quando la sincronizzazione la invia, il segnaposto nel cloud deve comunque conservare il nome della cartella eliminata: il nome va letto dalla copia del cloud nel momento dell'invio, come già avviene per il contenuto di una nota eliminata prima di scrivere il segnaposto. Fatto quando la cancellazione in coda contiene solo l'identificativo, e il cloud conserva il nome della cartella eliminata.
