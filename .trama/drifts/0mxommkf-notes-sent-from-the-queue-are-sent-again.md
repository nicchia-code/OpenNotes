---
status: resolved
resolution: fix-code
refs:
  - pending-change/Sent
  - requirements/data#cloud-sync
proposal: null
task: 526o0fg7
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:56.049Z
---
# Notes sent from the queue are sent again by the unsynced sweep

## What happens

Quando il cloud accetta un salvataggio di nota arrivato dalla coda, la nota resta sul dispositivo come mai sincronizzata. La sincronizzazione prosegue con il passo delle note non ancora sincronizzate, che invia di nuovo la stessa nota e solo dopo la segna come sincronizzata. Ogni nota salvata offline viene quindi inviata due volte nella stessa sincronizzazione.

## What should happen

La data di sincronizzazione di una nota resta vuota solo finché la nota non è mai stata sincronizzata. Una volta che il cloud ha accettato un cambiamento della nota, la nota risulta sincronizzata, e il passo delle note non ancora sincronizzate non dovrebbe inviarla di nuovo.

## Fix options

### Segnare la nota come sincronizzata

Quando il cloud accetta un salvataggio arrivato dalla coda, la data di sincronizzazione della nota viene impostata a quel momento, e il passo successivo la salta. Si evita l'invio doppio, al costo di una scrittura locale in più per ogni cambiamento inviato.

### Accettare l'invio doppio

Il passo delle note non ancora sincronizzate resta com'è e ogni nota salvata offline viene inviata due volte. Il cloud accetta la stessa scrittura senza danni, quindi nessun dato si perde, ma il traffico è doppio. Il requisito va allora riscritto: la data di sincronizzazione si imposta solo dopo quel passo.

## Where in the code

lib/core/services/sync_service.dart (syncNow: passo 1, invio della coda, che non tocca la nota locale; passo 3, note con data di sincronizzazione vuota)
