---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.TOKEN_REFRESHED
drift: myy7r511
proposal: null
agent: false
created: 2026-10-13T05:23:24.932Z
finished: 2026-10-13T05:24:37.505Z
---
# Fix code to match the Model: Renewed session does not reopen the realtime channel

## What happens

Quando la sessione viene rinnovata mentre il canale è aperto, il canale resta quello di prima: non viene chiuso né riaperto. Il codice lo prevede apposta: un rinnovo non è un nuovo accesso, quindi il canale si riapre solo se risulta chiuso.

## What should happen

Il Model dice che, mentre si ascolta, un rinnovo della sessione chiude il canale e ne apre uno nuovo, filtrato sull'utente connesso.

## Chosen option

**Riaprire il canale a ogni rinnovo**

Il canale viene chiuso e riaperto a ogni rinnovo della sessione, come scrive il Model, e riparte con il token nuovo. Costo: una riconnessione a ogni rinnovo del token, e le modifiche arrivate nel breve intervallo non vengono recuperate prima della sincronizzazione successiva.

## Where in the code

lib/core/services/sync_service.dart: _setupAuthListener (ramo TOKEN_REFRESHED)
