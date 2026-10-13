---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
proposal: null
task: r6bi0p5m
origin: x603i4hv
critical: false
option: 1
note: null
resolvedBy: ck9mt4x5
created: 2026-10-12T11:45:38.641Z
---
# Queued change older than cloud has no outcome in Model

## What happens

Quando la coda parte e la versione nel cloud è più recente della modifica in coda, la modifica viene tolta dalla coda senza essere inviata e senza alcun esito registrato. Il salvataggio più vecchio non sostituisce il cloud, e il dispositivo non tiene traccia dello scarto.

## What should happen

Il Model dice che una modifica in coda viene tolta solo dopo che il cloud l'ha accettata, senza scarti, e che la sua unica uscita è Inviata. Il Requirement di sincronizzazione dice che vince l'ultimo che ha scritto, quindi il salvataggio più vecchio non deve sostituire il cloud. Le due regole non si possono seguire insieme, perché il Model non ha un esito per la modifica scartata.

## Fix options

### Registrare lo scarto come esito

Il Model aggiunge un esito proprio alla coda per la modifica scartata perché il cloud è più recente; la modifica viene tolta dalla coda senza invio. Costo: chi scrive offline su una nota cambiata altrove perde il testo senza avviso.

### Inviare comunque

La modifica più vecchia viene inviata e sovrascrive il cloud. Costo: contraddice la regola dell'ultimo che ha scritto e può far perdere le modifiche più recenti fatte altrove.

### Tenere in coda

La modifica più vecchia resta in coda finché il cloud non è allineato, senza esito. Costo: la coda non si svuota e il Model dovrebbe ammettere un nuovo stato di attesa.

## Where in the code

lib/core/services/sync_service.dart
