---
column: done
technical: false
refs:
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
drift: q8gaqq0s
proposal: null
agent: false
created: 2026-10-17T10:25:21.869Z
finished: 2026-10-17T10:34:44.952Z
---
# Fix code to match the Model: Sign-in success message shown before the first sync ends

## What happens

Dopo un accesso riuscito la finestra delle impostazioni mostra 'Sincronizzazione completata con successo.' subito, mentre la prima sincronizzazione è ancora in corso. Il messaggio arriva prima della fine della sincronizzazione perché la finestra, quando riceve la notifica di inizio sincronizzazione, chiama di nuovo la sincronizzazione, che però esce subito perché è già in corso.

## What should happen

Il Model dice che, dopo l'accesso, la finestra annuncia 'Accesso completato! Sincronizzazione in corso...', esegue una sincronizzazione e solo poi annuncia 'Sincronizzazione completata con successo.'. Il messaggio di successo deve quindi comparire quando la sincronizzazione è davvero finita, altrimenti l'utente vede un esito non ancora vero.

## Chosen option

**Attendere la fine della sincronizzazione prima del messaggio**

La finestra aspetta che la sincronizzazione in corso finisca e solo dopo mostra il messaggio di successo. Non cambia il Model né i Requisiti. Costo: il messaggio di successo arriva più tardi, con la finestra in attesa.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn); lib/core/services/sync_service.dart (syncNow)
