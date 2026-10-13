---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - realtime-channel/Listening
proposal: null
task: l1miarna
origin: null
critical: false
option: 1
note: null
resolvedBy: 7lu86lzu
created: 2026-10-13T13:24:52.124Z
---
# Live cloud change drops a queued delete outside the sync run

## What happens

Quando una modifica del cloud arriva in tempo reale a una nota o a una cartella che questo dispositivo ha eliminato e la cui eliminazione è ancora in attesa di essere inviata, il sistema decide subito. Se il cloud ha cambiato la nota o la cartella dopo quell'eliminazione, l'eliminazione esce dalla coda e torna la versione del cloud. Altrimenti la modifica viene ignorata e l'eliminazione resta in coda. Un elemento della coda esce quindi fuori da una sincronizzazione.

## What should happen

Il Model dice che un cambiamento in coda esce dalla coda solo in una sincronizzazione completa, quando viene inviato o scartato, e che la sincronizzazione decide su un'eliminazione più vecchia dell'ultima modifica del cloud. Il canale in tempo reale, invece, deve applicare subito la versione del cloud quando il dispositivo non ha più la nota, e il Model non descrive il caso in cui un'eliminazione è ancora in coda.

## Fix options

### Leave the decision to the next sync run

La versione del cloud arriva subito, come ora, ma l'eliminazione resta in coda. La sincronizzazione successiva la scarta, perché il cloud è più recente, e la toglie dalla coda come scartata. Così l'unica uscita dalla coda per un'eliminazione è la sincronizzazione. Costo: una voce resta in coda fino alla prossima sincronizzazione.

### Ignore live changes while a delete waits

Finché un'eliminazione è in coda, il canale in tempo reale non applica modifiche del cloud a quella nota o cartella: la decisione resta alla sincronizzazione, come nel Model. Costo: la versione del cloud di una nota eliminata qui compare solo alla sincronizzazione successiva, mentre il canale oggi la riporta subito.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote e handleRemoteFolderChange, ramo con eliminazione in coda
