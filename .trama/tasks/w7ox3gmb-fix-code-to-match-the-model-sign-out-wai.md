---
column: done
technical: false
refs:
  - account/Signed in/user.SIGN_OUT
drift: 4ayj8yov
proposal: null
agent: false
created: 2026-10-12T10:59:40.520Z
finished: 2026-10-12T11:01:15.632Z
---
# Fix code to match the Model: Sign-out waits for local notes to upload

## What happens

Prima di chiudere la sessione, l'app carica sul cloud i cambiamenti in coda e le note mai sincronizzate. Se una nota o un cambiamento non può essere caricato, per esempio senza connessione, la disconnessione viene annullata: l'account resta connesso e la finestra mostra un errore. Le note locali non vanno perse, ma l'utente non può uscire dall'account finché il caricamento non riesce.

## What should happen

Il Model dice che disconnettersi chiude la sessione sul cloud e lascia le note locali e la coda sul dispositivo. Non prevede che la disconnessione possa essere annullata, né che prima si carichi tutto sul cloud. La scelta di caricare prima deriva dalla Drift sulle note locali dell'account, ma il Model non la riporta.

## Chosen option

**Describe the upload and the refusal in the Model**

Il Model descrive il caricamento prima della disconnessione e l'annullamento quando qualcosa non può essere caricato, come nella Proposal allegata. Il codice resta com'è. Costo: offline l'utente non può disconnettersi finché le note non sono caricate, e la regola diventa una nuova Transition dello stato Signed in.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleSignOut); lib/core/services/sync_service.dart (prepareSignOut)
