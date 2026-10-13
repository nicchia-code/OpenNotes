---
status: resolved
resolution: fix-code
refs:
  - account/Signed in
proposal: null
task: pb2b2in0
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:49:35.728Z
---
# Il rinnovo automatico della sessione avvia una sincronizzazione e riapre il canale in tempo reale

## What happens

Quando il servizio di autenticazione rinnova in automatico la sessione mentre l'utente è connesso, l'app avvia una sincronizzazione completa e riapre il canale in tempo reale, senza alcun gesto dell'utente. Il rinnovo avviene regolarmente durante l'uso, quindi la sincronizzazione si ripete.

## What should happen

Il Model fa partire sincronizzazione e canale in tempo reale solo con un accesso: sessione conservata all'avvio, accesso con Google o conferma del servizio cloud. Per lo stato **Signed in** non descrive il rinnovo della sessione, che per l'utente non è un nuovo accesso.

## Fix options

### Rinnovare solo la sessione

Il rinnovo aggiorna la sessione e basta. Il canale in tempo reale viene riaperto solo se risulta chiuso, senza sincronizzare: le modifiche fatte su altri dispositivi mentre il canale era chiuso arrivano alla prossima sincronizzazione. Il Model riceve una riga che descrive questo caso. Costo: possibile ritardo nel ricevere modifiche remote.

### Sincronizzare a ogni rinnovo e scriverlo nel Model

Il comportamento attuale resta: a ogni rinnovo parte una sincronizzazione completa e il canale viene riaperto. Il Model riceve una transizione per lo stato Signed in, così il comportamento è scritto. Costo: una sincronizzazione periodica anche senza modifiche, che può ricaricare le liste mentre l'utente lavora.

### Sincronizzare solo se il canale era chiuso

Il rinnovo riapre il canale e sincronizza solo se il canale era chiuso, così le modifiche perse durante un'interruzione arrivano subito. Il Model descrive questa regola. Costo: il codice deve distinguere lo stato del canale, e la sincronizzazione compare solo dopo una caduta della connessione.

## Where in the code

lib/core/services/sync_service.dart, ascoltatore dei cambi di sessione (eventi di rinnovo del token)
