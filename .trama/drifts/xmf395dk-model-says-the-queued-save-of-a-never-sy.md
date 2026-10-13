---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: 5gabmty7
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:24:43.569Z
---
# Model says the queued save of a never-synced note is sent, the code discards it when the note is deleted here

## What happens

Se una nota mai sincronizzata viene eliminata sul dispositivo prima della prima sincronizzazione, la sincronizzazione scarta il suo salvataggio in coda senza inviarlo. Nulla arriva al cloud, né il testo né gli allegati.

## What should happen

Il Model dice che il salvataggio in coda di una nota mai sincronizzata viene inviato intero, e non prevede lo scarto per una nota già eliminata sul dispositivo. Lo scarto è stato deciso sulla discrepanza precedente, ma il Model non lo ha ancora scritto.

## Fix options

### Write the discard in the Model

Il Model e il Requirement della coda dichiarano lo scarto esplicito per una nota eliminata sul dispositivo prima della prima sincronizzazione, come già previsto per le note eliminate nel cloud. Il comportamento resta com'è: il contenuto non lascia il dispositivo. Costo: una frase in più nel Model e nei requisiti; nessuna modifica al codice.

### Send the save as the Model says

Il salvataggio viene inviato al cloud intero, con gli allegati, e l'eliminazione in coda lo cancella subito dopo. Il Model resta invariato. Costo: il contenuto di una nota già eliminata passa per un istante nel cloud, con i suoi allegati caricati, e può arrivare ad altri dispositivi; traffico inutile.

## Where in the code

lib/core/services/sync_service.dart, syncNow, invio delle note in coda (controllo della nota locale prima dell'invio)
