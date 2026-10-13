---
column: done
technical: false
refs:
  - sync-run/Idle/supabase.SIGNED_IN
drift: null
proposal: null
agent: false
created: 2026-10-12T11:39:32.261Z
finished: 2026-10-12T13:57:54.192Z
---
# Fix code to match the Model: Sign-in starts a sync only while awaiting login, the Model needs only a session

## What happens

Nel codice l'evento di accesso avvia la sincronizzazione solo se l'app sta aspettando il ritorno dal browser (`_awaitingLogin`). Un evento di accesso che porta una sessione, arrivato quando l'app non sta aspettando, non fa partire nulla. Nel Model la Transition `supabase.SIGNED_IN` da Idle a Running ha come unica condizione che l'evento porti una sessione.

## What should happen

Ogni evento di accesso che porta una sessione fa passare la sincronizzazione da Idle a Running, come `INITIAL_SESSION` e `TOKEN_REFRESHED`. Il flag di attesa di accesso resta solo per il reset dopo il ritorno dal browser e non decide più se avviare la sincronizzazione. Una richiesta arrivata durante una sincronizzazione in corso continua a essere scartata.

## Where in the code

lib/core/services/sync_service.dart: `_setupAuthListener`, condizione su `AuthChangeEvent.signedIn`.
