---
column: done
technical: false
refs:
  - account/Signed in
drift: qf6ovb00
proposal: null
agent: false
created: 2026-10-17T13:41:35.354Z
finished: 2026-10-17T13:47:34.130Z
---
# Fix code to match the Model: Background session refresh error shows as a failed sign-in while signed in

## What happens

Mentre l'utente è connesso, se il rinnovo automatico della sessione fallisce per un errore temporaneo di rete, la finestra delle impostazioni mostra in rosso «Accesso non completato: <messaggio>» sotto i pulsanti, pur restando connesso. Il messaggio resta anche dopo la disconnessione, finché non parte un nuovo accesso o l'accesso riesce. Il motivo: ogni errore che il servizio di autenticazione notifica sul canale dei cambi di stato viene trattato come esito di un ritorno da Google.

## What should happen

Il Model dell'account mostra «Accesso non completato:» solo per un ritorno con errore tramite il collegamento dell'app, mentre l'app attende il ritorno dal browser. Nello stato Signed in il Model non descrive alcun messaggio di accesso e non prevede nulla per un rinnovo di sessione fallito: non dice se la finestra debba mostrarlo né quando debba sparire. Il comportamento attuale non si può quindi confrontare con il Model senza decidere che cosa mostrare.

## Chosen option

**Show only the errors of the sign-in return**

Il messaggio di accesso compare solo se l'errore arriva mentre l'app attende il ritorno dall'accesso; un rinnovo di sessione fallito non cambia la finestra e il Model resta com'è. Costo: un rinnovo fallito non compare come messaggio di accesso; se un giro di sincronizzazione fallisce, la sua categoria compare già nella finestra.

## Where in the code

lib/core/services/sync_service.dart: _setupAuthListener, ramo onError (imposta _awaitingLogin e _signInError); lib/ui/settings/supabase_settings_dialog.dart: riga che mostra «Accesso non completato:» quando signInError non è vuoto, fuori dal ramo degli utenti connessi. Errore sorgente: rinnovo del token della libreria di autenticazione, che notifica AuthRetryableFetchException sul canale dei cambi di stato.
