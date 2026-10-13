---
column: done
technical: false
refs:
  - account/Signed in
drift: fcz91q99
proposal: null
agent: false
created: 2026-10-12T18:00:24.449Z
finished: 2026-10-12T18:02:54.447Z
---
# Fix code to match the Model: Il rinnovo automatico della sessione avvia una sincronizzazione e riapre il canale in tempo reale

## What happens

Quando il servizio di autenticazione rinnova in automatico la sessione mentre l'utente è connesso, l'app avvia una sincronizzazione completa e riapre il canale in tempo reale, senza alcun gesto dell'utente. Il rinnovo avviene regolarmente durante l'uso, quindi la sincronizzazione si ripete.

## What should happen

Il Model fa partire sincronizzazione e canale in tempo reale solo con un accesso: sessione conservata all'avvio, accesso con Google o conferma del servizio cloud. Per lo stato **Signed in** non descrive il rinnovo della sessione, che per l'utente non è un nuovo accesso.

## Chosen option

**Rinnovare solo la sessione**

Il rinnovo aggiorna la sessione e basta. Il canale in tempo reale viene riaperto solo se risulta chiuso, senza sincronizzare: le modifiche fatte su altri dispositivi mentre il canale era chiuso arrivano alla prossima sincronizzazione. Il Model riceve una riga che descrive questo caso. Costo: possibile ritardo nel ricevere modifiche remote.

## Where in the code

lib/core/services/sync_service.dart, ascoltatore dei cambi di sessione (eventi di rinnovo del token)
