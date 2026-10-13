---
column: done
technical: false
refs:
  - realtime-channel/Closed/supabase.SIGNED_IN
  - realtime-channel/Listening/supabase.SIGNED_IN
drift: null
proposal: null
agent: false
created: 2026-10-12T12:03:43.357Z
finished: 2026-10-12T13:55:29.246Z
---
# Fix code to match the Model: Realtime channel does not open on sign-in unless awaiting login

## What happens

Nel codice il canale in tempo reale si apre o si riapre su un evento di accesso che porta una sessione solo se l'app sta aspettando il ritorno dal browser (`_awaitingLogin`). Un accesso arrivato quando questo flag è spento non apre il canale, né da Chiuso né da In ascolto. Nel Model la Transition `supabase.SIGNED_IN` del canale ha come unica condizione che l'evento porti una sessione.

## What should happen

Ogni evento di accesso che porta una sessione apre il canale in tempo reale sulle note e cartelle dell'utente connesso: da Chiuso passa a In ascolto, e da In ascolto chiude il canale e ne apre uno nuovo, come per `INITIAL_SESSION` e `TOKEN_REFRESHED`. Il flag di attesa di accesso resta solo per il reset dopo il ritorno dal browser e non decide più se il canale si apre.

## Where in the code

lib/core/services/sync_service.dart: `_setupAuthListener`, condizione su `AuthChangeEvent.signedIn` (la stessa condizione decide la sincronizzazione: il Task sogqn8i2 la copre per il lato sincronizzazione; qui serve il canale).
