---
column: done
technical: false
refs:
  - sync-run/Pulling
drift: xportynf
proposal: null
agent: false
created: 2026-10-12T07:38:53.766Z
finished: 2026-10-12T07:41:36.478Z
---
# Fix code to match the Model: Downloaded notes lose their link to the vault file

## What happens

Quando una nota del cloud sostituisce quella locale, la copia salvata nel database perde il collegamento al suo file nel vault. Il file viene riscritto con un nome calcolato dal titolo: se il titolo è cambiato rispetto al file esistente, nel vault compare un file nuovo e quello vecchio resta.

## What should happen

La versione del cloud sostituisce quella locale e il suo file nel vault viene riscritto: lo stesso file, non un file nuovo. Il collegamento tra la nota e il suo file deve restare valido dopo il download.

## Chosen option

**Keep the local file location when replacing**

Il download riscrive il file che la nota già aveva nel vault, anche se il titolo arrivato dal cloud è diverso, e mantiene il collegamento. Nessun file doppio. Costo: il file mantiene il nome di prima, come già avviene al salvataggio di una nota locale.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo di download delle note (upsertNote con la nota del cloud, poi saveNote); lib/core/services/vault_service.dart: saveNote, nome del file calcolato dal titolo quando la nota non ha percorso.
