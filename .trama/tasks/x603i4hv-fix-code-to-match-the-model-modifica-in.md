---
column: done
technical: false
refs:
  - pending-change/Queued
drift: ck9jspjh
proposal: null
agent: false
created: 2026-10-12T11:44:40.867Z
finished: 2026-10-12T14:02:07.487Z
---
# Fix code to match the Model: Modifica in coda più vecchia del cloud senza esito nel Model

## What happens

Quando la coda parte e il cloud ha già una versione più recente della nota, la modifica in coda più vecchia viene tolta dalla coda senza essere inviata e senza alcun esito registrato. Il codice la scarta come previsto dalla regola dell'ultimo che ha scritto.

## What should happen

Il Model dice che la modifica in coda viene tolta solo dopo che il cloud l'ha accettata, senza scarti, e che la sua unica uscita è Inviata. Il Requirement di sincronizzazione dice invece che vince l'ultimo che ha scritto, quindi il salvataggio più vecchio non deve sostituire il cloud. Le due regole non si possono seguire insieme: la scelta concordata (scartare e registrare un esito) non è ancora nel Model, quindi non esiste uno stato o una transizione in cui il codice possa portare la modifica scartata.

## Chosen option

**Registrare lo scarto come esito della modifica**

Il Model aggiunge un esito proprio alla coda per la modifica scartata perché il cloud è più recente; la modifica viene tolta dalla coda senza invio. Costo: la regola di rimozione va riscritta e chi scrive offline su una nota cambiata altrove perde il testo senza avviso.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 1 della coda, ramo delle note (confronto con la data del cloud, poi rimozione dell'elemento)
