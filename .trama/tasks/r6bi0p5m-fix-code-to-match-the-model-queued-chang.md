---
column: done
technical: false
refs:
  - pending-change/Queued
drift: qs2a8nc6
proposal: null
agent: false
created: 2026-10-12T11:53:12.019Z
finished: 2026-10-12T13:56:30.210Z
---
# Fix code to match the Model: Queued change older than cloud has no outcome in Model

## What happens

Quando la coda parte e la versione nel cloud è più recente della modifica in coda, la modifica viene tolta dalla coda senza essere inviata e senza alcun esito registrato. Il salvataggio più vecchio non sostituisce il cloud, e il dispositivo non tiene traccia dello scarto.

## What should happen

Il Model dice che una modifica in coda viene tolta solo dopo che il cloud l'ha accettata, senza scarti, e che la sua unica uscita è Inviata. Il Requirement di sincronizzazione dice che vince l'ultimo che ha scritto, quindi il salvataggio più vecchio non deve sostituire il cloud. Le due regole non si possono seguire insieme, perché il Model non ha un esito per la modifica scartata.

## Chosen option

**Registrare lo scarto come esito**

Il Model aggiunge un esito proprio alla coda per la modifica scartata perché il cloud è più recente; la modifica viene tolta dalla coda senza invio. Costo: chi scrive offline su una nota cambiata altrove perde il testo senza avviso.

## Where in the code

lib/core/services/sync_service.dart
