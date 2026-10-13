---
column: done
technical: false
refs:
  - pending-change/Queued
drift: 19uk21bm
proposal: null
agent: false
created: 2026-10-12T16:25:09.277Z
finished: 2026-10-12T16:40:03.861Z
---
# Fix code to match the Model: Later queued changes of a note already in the cloud are dropped by its own first send

## What happens

Quando una nota già presente nel cloud ha più modifiche in attesa, per esempio perché è stata cambiata più volte offline, alla sincronizzazione parte la prima e il cloud registra l'ora del suo invio. Le modifiche successive vengono confrontate con quella copia, scritta poco prima dallo stesso dispositivo, risultano più vecchie e vengono scartate senza avviso. Al download la versione della prima modifica sostituisce il testo più recente, che va perso. Lo stesso accade quando una nota modificata offline viene poi eliminata definitivamente: la modifica parte, il cloud risulta più recente dell'eliminazione, quindi l'eliminazione viene scartata e la nota ricompare. Anche una cartella rinominata e poi eliminata offline torna.

## What should happen

Il Requirement dice che vince l'ultimo che ha scritto, confrontando le date, e che un'eliminazione in coda viene scartata solo se il cloud è stato modificato dopo di essa, cioè da un altro dispositivo. La regola non dice se una modifica già inviata da questo stesso dispositivo nella stessa sincronizzazione conta come modifica del cloud. Leggendola alla lettera la risposta è sì, e così si perde l'ultima modifica: le modifiche in coda di una nota devono arrivare in ordine, e un'eliminazione fatta dopo una modifica deve restare eliminazione.

## Chosen option

**Confrontare con la copia del cloud di prima della sincronizzazione**

Le date del cloud si leggono una volta, all'inizio della sincronizzazione, e ogni modifica o eliminazione in coda si confronta con quella copia. Le modifiche di una nota arrivano in ordine e vince l'ultima; un'eliminazione fatta dopo una modifica resta eliminazione. Costo: una lettura iniziale delle note in coda; una modifica fatta su un altro dispositivo durante la stessa sincronizzazione può essere sovrascritta. Il Requirement non cambia.

## Where in the code

lib/core/services/sync_service.dart: syncNow, ramo delle note in coda (confronto con updated_at del cloud); applyRemoteNote, che sostituisce la copia locale più vecchia del cloud
