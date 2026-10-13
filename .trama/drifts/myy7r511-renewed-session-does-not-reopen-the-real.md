---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.TOKEN_REFRESHED
proposal: null
task: iwyuc8wb
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:21:05.080Z
---
# Renewed session does not reopen the realtime channel

## What happens

Quando la sessione viene rinnovata mentre il canale è aperto, il canale resta quello di prima: non viene chiuso né riaperto. Il codice lo prevede apposta: un rinnovo non è un nuovo accesso, quindi il canale si riapre solo se risulta chiuso.

## What should happen

Il Model dice che, mentre si ascolta, un rinnovo della sessione chiude il canale e ne apre uno nuovo, filtrato sull'utente connesso.

## Fix options

### Riaprire il canale a ogni rinnovo

Il canale viene chiuso e riaperto a ogni rinnovo della sessione, come scrive il Model, e riparte con il token nuovo. Costo: una riconnessione a ogni rinnovo del token, e le modifiche arrivate nel breve intervallo non vengono recuperate prima della sincronizzazione successiva.

### Mantenere il canale e correggere il Model

Il canale resta aperto anche al rinnovo, come oggi, e il Model va riscritto: in ascolto un rinnovo non chiude il canale. Nessuna riconnessione. Costo: va verificato che il canale usi il token rinnovato; se non lo usa, le modifiche arrivano su una sessione scaduta.

## Where in the code

lib/core/services/sync_service.dart: _setupAuthListener (ramo TOKEN_REFRESHED)
