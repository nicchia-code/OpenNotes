---
status: resolved
resolution: fix-code
refs:
  - account/Signed in/user.SIGN_OUT
proposal: null
task: w7ox3gmb
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:46:24.809Z
---
# Sign-out waits for local notes to upload

## What happens

Prima di chiudere la sessione, l'app carica sul cloud i cambiamenti in coda e le note mai sincronizzate. Se una nota o un cambiamento non può essere caricato, per esempio senza connessione, la disconnessione viene annullata: l'account resta connesso e la finestra mostra un errore. Le note locali non vanno perse, ma l'utente non può uscire dall'account finché il caricamento non riesce.

## What should happen

Il Model dice che disconnettersi chiude la sessione sul cloud e lascia le note locali e la coda sul dispositivo. Non prevede che la disconnessione possa essere annullata, né che prima si carichi tutto sul cloud. La scelta di caricare prima deriva dalla Drift sulle note locali dell'account, ma il Model non la riporta.

## Fix options

### Describe the upload and the refusal in the Model

Il Model descrive il caricamento prima della disconnessione e l'annullamento quando qualcosa non può essere caricato, come nella Proposal allegata. Il codice resta com'è. Costo: offline l'utente non può disconnettersi finché le note non sono caricate, e la regola diventa una nuova Transition dello stato Signed in.

### Sign out at once and keep the queue on the device

La disconnessione chiude subito la sessione senza caricare nulla: la coda resta sul dispositivo e viene inviata al prossimo account che si connette. Costo: si torna indietro sulla scelta della Drift sulle note locali, e il nuovo utente può ricevere note scritte da un altro account. Il Model resta com'è.

### Try the upload, then sign out anyway

La disconnessione prova a caricare le note, ma chiude la sessione comunque se il caricamento fallisce. Nessuna disconnessione viene bloccata. Costo: le note non caricate restano sul dispositivo senza un account finché l'utente non si riconnette; il Model va scritto di conseguenza.

## Where in the code

lib/ui/settings/supabase_settings_dialog.dart (_handleSignOut); lib/core/services/sync_service.dart (prepareSignOut)
