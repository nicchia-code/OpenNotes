---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - requirements/rules#cloud-sync
proposal: null
task: 0ytk1b6k
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:21:04.254Z
---
# Queued folder or note delete loses to a cloud copy with the same time

## What happens

Quando la copia del cloud di una nota o di una cartella ha la stessa ora di modifica dell'eliminazione ancora in coda, il download e il tempo reale non applicano la copia del cloud. La nota o la cartella resta eliminata qui, e l'eliminazione aspetta il giro di invio. Solo lì il cloud la riporta indietro, perché a parità vince il cloud.

## What should happen

La regola «vince l'ultima modifica» dice che la copia locale, anche un'eliminazione in coda, vince solo se è strettamente più recente della copia del cloud; a parità vince il cloud. La regola vale anche per il download e per il tempo reale, non solo per l'invio. La copia del cloud va quindi applicata subito.

## Fix options

### Apply the cloud copy on a tie, as the send does

Sul download e sul tempo reale la copia del cloud vince quando la sua ora non è anteriore a quella dell'eliminazione in coda: l'eliminazione viene tolta e la copia applicata subito. Cambia solo il caso di pari ora, e il comportamento coincide con quello dell'invio. Costo: piccolo; vanno aggiunti i test dei pari ora sulle note e sulle cartelle.

### Decide the tie in one shared rule

Il confronto tra copia locale e copia del cloud passa in un'unica funzione usata dall'invio, dal download e dal tempo reale, così la parità non può più decidersi in modo diverso nelle tre strade. Il risultato è lo stesso della prima opzione. Costo: una modifica più ampia nella sincronizzazione, con i test delle tre strade da riallineare.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (ramo dell'eliminazione in coda) e _storeCloudFolder (ramo dell'eliminazione in coda), confrontati con il confronto di pari ora in _pushRow.
