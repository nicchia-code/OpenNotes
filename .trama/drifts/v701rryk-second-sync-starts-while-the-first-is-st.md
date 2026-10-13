---
status: resolved
resolution: fix-code
refs:
  - sync-run
  - requirements/rules#sync-run
proposal: null
task: yywp6az8
origin: null
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T14:16:31.948Z
---
# Second sync starts while the first is still running at startup

## What happens

All'avvio la preparazione del collegamento avvia una sincronizzazione e poi spegne il segnale di sincronizzazione in corso, mentre la prima è ancora in corso. Così l'avvio dell'app ne lancia una seconda in parallelo, e ogni modifica fatta durante la prima può avviarne un'altra: le stesse modifiche in coda possono essere inviate due volte.

## What should happen

Una sola sincronizzazione alla volta: le richieste che arrivano durante una sincronizzazione in corso, o mentre il collegamento viene preparato, vengono scartate senza essere ripetute. Due sincronizzazioni non devono mai correre insieme.

## Fix options

### Non spegnere il segnale prima della fine

Lasciare che il segnale di sincronizzazione in corso si spenga solo alla fine della sincronizzazione di avvio, così nessuna richiesta parte in parallelo. Costo: la preparazione e l'avvio aspettano la fine della sincronizzazione, come già previsto per l'avvio.

### Avviare la sincronizzazione una sola volta

Togliere la sincronizzazione dalla preparazione del collegamento e lasciare che l'avvio dell'app ne lanci una sola. Costo: va verificato che l'evento di sessione iniziale non venga perso; altrimenti una sessione salvata sincronizza solo al passo di avvio.

## Where in the code

lib/core/services/sync_service.dart, funzione initializeSupabase (avvio della sincronizzazione e spegnimento del segnale); lib/main.dart, chiamata di avvio a syncNow.
