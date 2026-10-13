---
status: resolved
resolution: fix-code
refs:
  - sync-run/Idle
proposal: null
task: ml1teic5
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:24:43.495Z
---
# Model still starts a sync run on token renewal, the code only reopens the channel

## What happens

Quando il servizio di accesso rinnova la sessione mentre l'utente è connesso, l'app non avvia nessuna sincronizzazione: riapre il canale in tempo reale solo se risulta chiuso.

## What should happen

Il Model della sincronizzazione dice che il rinnovo della sessione porta lo stato In esecuzione, cioè una sincronizzazione completa. La decisione presa sulla discrepanza precedente, cioè rinnovare solo la sessione senza sincronizzare, non è ancora scritta in questo stato del Model.

## Fix options

### Remove the renewal from the sync run

Il Model della sincronizzazione non fa più partire una sincronizzazione al rinnovo della sessione; resta solo la riapertura del canale, già descritta nel Model del canale. Costo: le modifiche fatte su altri dispositivi mentre il canale era chiuso arrivano solo alla sincronizzazione successiva.

### Sync on every renewal

Il rinnovo della sessione fa partire una sincronizzazione completa, come dice il Model oggi. Il codice va cambiato per sincronizzare anche al rinnovo. Costo: una sincronizzazione periodica anche senza modifiche, che può ricaricare le liste mentre l'utente lavora.

## Where in the code

lib/core/services/sync_service.dart, ascoltatore dei cambi di sessione
