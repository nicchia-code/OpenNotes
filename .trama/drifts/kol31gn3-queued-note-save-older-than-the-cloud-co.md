---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - requirements/rules#pending-change
proposal: null
task: ru28nuer
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:21:32.140Z
---
# Queued note save older than the cloud copy is removed without being sent

## What happens

Quando la coda parte e il cloud ha già una versione più recente di una nota, il salvataggio in coda più vecchio viene tolto dalla coda senza essere inviato. La modifica sparisce e il cloud non la riceve mai. Nel Diagramma della modifica in coda non c'è nessuna uscita per questo caso: la modifica arriva a **Inviata** solo quando il cloud la accetta.

## What should happen

Il Requirement sulle regole di accodamento dice che un elemento viene rimosso dalla coda **solo dopo che il cloud lo ha accettato**, senza scarti. Il Requirement sulle regole di sincronizzazione dice invece che per le note **vince l'ultimo che ha scritto**, quindi un salvataggio più vecchio del cloud non deve sostituirlo. Non si possono seguire entrambe le regole senza scegliere: il salvataggio perdente o resta in coda, o viene tolto senza essere accettato.

## Fix options

### Discard the older save and record it as an outcome

Il salvataggio più vecchio del cloud viene scartato, come oggi, e il Model lo dichiara: la modifica ha un esito proprio nel Diagramma della coda, che non è più solo **Inviata**. Costo: la regola di rimozione dei Requirement va riscritta, e chi scrive offline su una nota cambiata altrove perde il testo senza avviso.

### Keep the older save in the queue

Il salvataggio più vecchio non viene inviato né tolto: resta in coda e a ogni sincronizzazione viene confrontato di nuovo con il cloud. Nessuna modifica sparisce senza essere accettata, come dice il Requirement. Costo: la coda può crescere con elementi che non partiranno mai, e serve una regola per liberarli quando la nota cambia ancora o viene eliminata.

### Send the older save and let it overwrite

Il salvataggio più vecchio viene inviato come le altre modifiche e il cloud accetta la versione meno recente, come prima della correzione. Nessuna modifica viene scartata, ma un testo scritto offline può sostituire una versione più recente scritta su un altro dispositivo. Costo: va riscritta la regola dell'ultimo che ha scritto per le note, nei Requirement e nel Model.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 1 della coda, ramo delle note (confronto con la data del cloud, poi rimozione dell'elemento)
