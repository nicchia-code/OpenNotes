---
column: done
technical: false
refs:
  - account/Awaiting login
  - requirements/rules#account
drift: nmye93fq
proposal: null
agent: false
created: 2026-10-17T17:39:37.198Z
finished: 2026-10-17T17:41:19.393Z
---
# Fix code to match the Model: Settings window waits for a sign-in sync that already started

## What happens

Se l'accesso Google finisce mentre una sincronizzazione è già in corso, la finestra delle impostazioni resta su **"Accesso completato! Sincronizzazione in corso..."** anche dopo la fine di quella sincronizzazione. La finestra aspetta che una sincronizzazione parta e poi finisca, ma quella dell'accesso era già partita: la sua fine non viene riconosciuta, e l'esito compare solo alla sincronizzazione successiva, di solito dopo circa un minuto.

## What should happen

Dopo l'accesso la finestra attende la **fine del giro avviato dall'accesso**, anche se quel giro ne fa partire un altro, e solo allora annuncia il risultato: "Sincronizzazione completata con successo.", oppure la categoria dell'errore con il nuovo tentativo. Non avvia un secondo giro.

## Chosen option

**Notify the window at the end of every run**

Il servizio di sincronizzazione avvisa la finestra alla fine di ogni giro, anche di quello che termina subito dopo il ritorno dal browser. La finestra non dipende più dall'avvio di un giro, ma dalla sua fine, e mostra l'esito appena il giro finisce. Costo: un avviso in più per ogni giro, e un controllo in più nella finestra.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (attesa dopo l'accesso, _handleGoogleSignIn); lib/core/services/sync_service.dart (ascolto del cambio di accesso e avvio dei giri, _setupAuthListener e _start)
