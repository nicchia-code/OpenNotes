---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - sync-run/Pushing changes
proposal: null
task: sa7kcg5q
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:18:23.262Z
---
# Queued save of a note deleted before its first sync is dropped, the Model says it is sent

## What happens

Se una nota non ancora sincronizzata viene eliminata sul dispositivo prima della prima sincronizzazione, la sincronizzazione scarta il suo salvataggio in coda senza inviarlo: nulla arriva al cloud, né il testo né gli allegati, e l'eliminazione in coda non trova nulla da cancellare.

## What should happen

Il Model dice che, alla sincronizzazione, un salvataggio in coda di una nota mai sincronizzata viene inviato intero. Per una nota già eliminata sul dispositivo il Model non prevede lo scarto: nei requisiti della coda manca questo caso, che invece è previsto per le note eliminate nel cloud.

## Fix options

### Keep the discard and write it in the Model

Il caso diventa uno scarto esplicito, nel Model e nei requisiti della coda, come quello delle note eliminate altrove. Il comportamento resta quello attuale: il contenuto di una nota già eliminata non lascia il dispositivo, nemmeno per un istante. Costo: il Proposal collegato aggiunge una frase a un evento e a un requisito; nessuna modifica al codice.

### Send the save, as the Model says

Il salvataggio viene inviato al cloud intero, con gli allegati, e l'eliminazione in coda lo cancella subito dopo. Il Model resta invariato. Costo: il contenuto di una nota già eliminata finisce per un istante nel cloud, con i suoi allegati caricati, e altri dispositivi possono riceverlo; traffico inutile e una modifica del codice da rimuovere il controllo sulla nota locale.

## Where in the code

lib/core/services/sync_service.dart: invio dei salvataggi di note in coda, controllo della nota locale prima dell'invio.
