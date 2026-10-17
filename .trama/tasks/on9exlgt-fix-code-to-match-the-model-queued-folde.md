---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:13.112Z
finished: 2026-10-17T15:41:39.105Z
---
# Fix code to match the Model: Queued folder create or rename overwrites the cloud copy without comparing times

# Comportamento atteso
Creazione o rinomina di una cartella in coda segue le regole di un salvataggio di nota: se la cartella del cloud è stata modificata dopo l'ultima modifica locale, la modifica locale viene scartata e la versione del cloud arriva con il download; se la copia locale è strettamente più recente, viene inviata sopra quella del cloud. Lo stesso confronto vale per una cartella eliminata nel cloud dopo l'ultima modifica locale. Il Model (sync-run) e il Requirement (vince l'ultima modifica, anche per l'invio della coda) dicono questo.

# Stato attuale
Una creazione o rinomina in coda viene sempre inviata e sovrascrive la cartella del cloud, senza confronto di date. Il commento nel codice cita una regola precedente del Model.

# Fatto quando
Una rinomina locale più vecchia di una modifica della cartella nel cloud non la sovrascrive; una rinomina locale più recente la sostituisce.
