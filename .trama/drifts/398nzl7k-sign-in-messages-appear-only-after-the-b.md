---
status: resolved
resolution: proposal
refs:
  - account
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: yvoxqf2h
created: 2026-10-17T07:39:55.850Z
---
# Sign-in messages appear only after the browser returns

## What happens

Mentre il browser è aperto sull'accesso Google, la finestra delle impostazioni non mostra nessun messaggio: compaiono "Accesso completato! Sincronizzazione in corso..." e "Sincronizzazione completata con successo." solo dopo il ritorno da Google. La sincronizzazione viene eseguita davvero, e non è ignorata.

## What should happen

Il Model dice che, appena il browser è aperto, la finestra annuncia "Accesso completato! Sincronizzazione in corso...", chiede una sincronizzazione (ignorata perché nessun utente è ancora connesso) e poi annuncia "Sincronizzazione completata con successo.". Nel codice questi messaggi compaiono solo dopo il ritorno.

## Fix options

### Show the messages as the Model says

Mostrare i tre messaggi appena il browser è aperto, come scritto nel Model, e lasciare ignorata la sincronizzazione. Costo: "Accesso completato!" compare prima che l'accesso sia avvenuto, anche se poi fallisce.

### Keep the messages after the return and change the Model

Tenere il comportamento attuale: i messaggi compaiono dopo il ritorno, e il Model viene corretto tramite una Proposal. Costo: serve una Proposal per cambiare il Model; il codice resta com'è.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleGoogleSignIn, _waitForReturn)
