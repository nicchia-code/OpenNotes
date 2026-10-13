---
column: done
technical: false
refs:
  - sync-run/Idle
drift: hx8s6yah
proposal: null
agent: false
created: 2026-10-13T05:49:16.195Z
finished: 2026-10-13T05:51:23.169Z
---
# Fix code to match the Model: Model still starts a sync run on token renewal, the code only reopens the channel

## What happens

Quando il servizio di accesso rinnova la sessione mentre l'utente è connesso, l'app non avvia nessuna sincronizzazione: riapre il canale in tempo reale solo se risulta chiuso.

## What should happen

Il Model della sincronizzazione dice che il rinnovo della sessione porta lo stato In esecuzione, cioè una sincronizzazione completa. La decisione presa sulla discrepanza precedente, cioè rinnovare solo la sessione senza sincronizzare, non è ancora scritta in questo stato del Model.

## Chosen option

**Remove the renewal from the sync run**

Il Model della sincronizzazione non fa più partire una sincronizzazione al rinnovo della sessione; resta solo la riapertura del canale, già descritta nel Model del canale. Costo: le modifiche fatte su altri dispositivi mentre il canale era chiuso arrivano solo alla sincronizzazione successiva.

## Where in the code

lib/core/services/sync_service.dart, ascoltatore dei cambi di sessione
