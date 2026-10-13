---
column: done
technical: false
refs:
  - pending-change/Sent
  - requirements/data#cloud-sync
drift: 0mxommkf
proposal: null
agent: false
created: 2026-10-12T07:38:53.722Z
finished: 2026-10-12T07:46:16.446Z
---
# Fix code to match the Model: Notes sent from the queue are sent again by the unsynced sweep

## What happens

Quando il cloud accetta un salvataggio di nota arrivato dalla coda, la nota resta sul dispositivo come mai sincronizzata. La sincronizzazione prosegue con il passo delle note non ancora sincronizzate, che invia di nuovo la stessa nota e solo dopo la segna come sincronizzata. Ogni nota salvata offline viene quindi inviata due volte nella stessa sincronizzazione.

## What should happen

La data di sincronizzazione di una nota resta vuota solo finché la nota non è mai stata sincronizzata. Una volta che il cloud ha accettato un cambiamento della nota, la nota risulta sincronizzata, e il passo delle note non ancora sincronizzate non dovrebbe inviarla di nuovo.

## Chosen option

**Segnare la nota come sincronizzata**

Quando il cloud accetta un salvataggio arrivato dalla coda, la data di sincronizzazione della nota viene impostata a quel momento, e il passo successivo la salta. Si evita l'invio doppio, al costo di una scrittura locale in più per ogni cambiamento inviato.

## Where in the code

lib/core/services/sync_service.dart (syncNow: passo 1, invio della coda, che non tocca la nota locale; passo 3, note con data di sincronizzazione vuota)
